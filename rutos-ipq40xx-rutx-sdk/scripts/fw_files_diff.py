#!/usr/bin/env python3
from __future__ import annotations

import argparse
import logging
import re
from os import get_terminal_size, getenv
from pathlib import Path
from shlex import quote
from subprocess import PIPE, Popen, run
from sys import exit as sys_exit
from sys import stderr

from sqlalchemy import Column, Enum, ForeignKey, Integer, String, create_engine, func, or_
from sqlalchemy.orm import Session, aliased, declarative_base, sessionmaker


class bcolors:  # noqa: D101, N801
    HEADER = "\033[95m"
    OKBLUE = "\033[94m"
    OKCYAN = "\033[96m"
    OKGREEN = "\033[92m"
    WARNING = "\033[93m"
    FAIL = "\033[91m"
    ENDC = "\033[0m"
    BOLD = "\033[1m"
    UNDERLINE = "\033[4m"


def config() -> None:
    """Assign arbitrary properties to the config object.

    Returns:
        None

    """
    return


config.size_width = 9
config.size_regex = re.compile(r"\.0+$")
config.separator = "-"
config.default_no_value_str = "-"
config.units = ["", "k", "M", "G"]
config.unit_multiple = 1024
config.file_list_types = ["fw", "gpl", "ipk"]
config.script_dir = Path(__file__).resolve().parent
config.top_dir = config.script_dir.parent


def exit_w_err(err: str, code: int = 1) -> None:
    """Print an error message to stderr and exit the program with the given exit code.

    Args:
        err (str): The error message to be printed.
        code (int, optional): The exit code for the program. Defaults to 1.

    Returns:
        None

    """
    stderr.write(err + "\n")
    sys_exit(code)


class Database:
    """Database class to handle MySQL database interactions using SQLAlchemy ORM.

    Attributes:
        Base (declarative_base): Base class for declarative class definitions.
        engine (Engine): SQLAlchemy Engine instance for database connection.
        session (Session): SQLAlchemy Session instance for database operations.

    Methods:
        __init__(user, password, host, port, database):
            Initializes the Database instance with connection parameters and creates tables.

    """

    Base = declarative_base()

    def __init__(self, user: str, password: str, host: str, port: int, database: str) -> None:
        """Initialize the Database instance with connection parameters and create tables.

        Args:
            user (str): The database user.
            password (str): The database password.
            host (str): The database host.
            port (int): The database port.
            database (str): The database name.

        """

        # Enable SQLAlchemy logging
        logging.basicConfig()
        logging.getLogger("sqlalchemy.engine").setLevel(logging.DEBUG)

        self.engine = create_engine(f"mysql+pymysql://{user}:{password}@{host}:{port}/{database}")
        self.Base.metadata.create_all(self.engine)

        session = sessionmaker()
        session.configure(bind=self.engine)
        self.session = session()

    class Device(Base):
        """Represents a device in the database.

        Attributes:
            id (int): The unique identifier for the device.
            name (str): The name of the device.

        Methods:
            fetch(session: Session, name: str) -> object:
                Fetches a device by name from the database. Raises a ValueError if the device is not found.

            fetch_or_create(session: Session, name: str) -> object:
                Fetches a device by name from the database. If the device does not exist, it creates a new device with the given name.

        """

        __tablename__ = "devices"
        id = Column(Integer, primary_key=True)
        name = Column(String(255))

        @staticmethod
        def fetch(session: Session, name: str) -> object:
            """Fetch a device from the database by its name.

            Args:
                session (Session): The database session to use for the query.
                name (str): The name of the device to fetch.

            Returns:
                object: The device object if found.

            Raises:
                ValueError: If the device with the given name is not found in the database.

            """
            device = session.query(Database.Device).filter_by(name=name).first()

            if not device:
                msg = f"Device {name} not found in database"
                raise ValueError(msg)

            return device

        @staticmethod
        def fetch_or_create(session: Session, name: str) -> object:
            """Fetch or create a device by its name.

            Args:
                session (Session): The database session to use for the query.
                name (str): The name of the device to fetch or create.

            Returns:
                object: The device object.

            """
            device = session.query(Database.Device).filter_by(name=name).first()

            if not device:
                device = Database.Device(name=name)
                session.add(device)
                session.commit()

            return device

    class FileTypes(Base):
        """Represents a file type in the database.

        Attributes:
            id (int): The unique identifier for the file type.
            name (str): The name of the file type.

        Methods:
            fetch_or_create(session: Session, name: str) -> object:
                Fetches a file type by name from the database. If the file type does not exist, it creates a new file type with the given
                name.

        """

        __tablename__ = "file_types"
        id = Column(Integer, primary_key=True)
        name = Column(Enum(*config.file_list_types))

        @staticmethod
        def fetch_or_create(session: Session, name: str) -> object:
            """Fetch or create a file type by its name.

            Args:
                session (Session): The database session to use for the query.
                name (str): The name of the file type to fetch or create.

            Returns:
                object: The file type object.

            """
            file_type = session.query(Database.FileTypes).filter_by(name=name).first()

            if not file_type:
                file_type = Database.FileTypes(name=name)
                session.add(file_type)
                session.commit()

            return file_type

    class File(Base):
        """Represents a file in the database.

        Attributes:
            id (int): The unique identifier for the file.
            name (str): The name of the file.
            file_type_id (int): The identifier for the file type.

        Methods:
            fetch_or_create(session: Session, name: str, f_type_id: int) -> object:
                Fetches a file by name and file type ID from the database. If the file does not exist, it creates a new file with the given
                name and file type ID.

        """

        __tablename__ = "files"
        id = Column(Integer, primary_key=True)
        name = Column(String(1024))
        file_type_id = Column(Integer, ForeignKey("file_types.id"))

        @staticmethod
        def fetch_or_create(session: Session, name: str, f_type_id: int) -> object:
            """Fetch or create a file by its name and file type ID.

            Args:
                session (Session): The database session to use for the query.
                name (str): The name of the file to fetch or create.
                f_type_id (int): The file type ID.

            Returns:
                object: The file object.

            """
            file = session.query(Database.File).filter_by(name=func.binary(name), file_type_id=f_type_id).first()

            if not file:
                file = Database.File(name=name, file_type_id=f_type_id)
                session.add(file)
                session.commit()

            return file

    class Branch(Base):
        """Represents a branch in the database.

        Attributes:
            id (int): The unique identifier for the branch.
            name (str): The name of the branch.

        Methods:
            fetch(session: Session, name: str) -> object:
                Fetches a branch by name from the database. Raises a ValueError if the branch is not found.

            fetch_or_create(session: Session, name: str) -> object:
                Fetches a branch by name from the database. If the branch does not exist, it creates a new branch with the given name.

        """

        __tablename__ = "branches"
        id = Column(Integer, primary_key=True)
        name = Column(String(1024))

        @staticmethod
        def fetch(session: Session, name: str) -> object:
            """Fetch a branch from the database by its name.

            Args:
                session (Session): The database session to use for the query.
                name (str): The name of the branch to fetch.

            Returns:
                object: The branch object if found.

            Raises:
                ValueError: If the branch with the given name is not found in the database.

            """
            branch = session.query(Database.Branch).filter_by(name=name).first()

            if not branch:
                msg = f"Branch {name} not found in database"
                raise ValueError(msg)

            return branch

        @staticmethod
        def fetch_or_create(session: Session, name: str) -> object:
            """Fetch or create a branch by its name.

            Args:
                session (Session): The database session to use for the query.
                name (str): The name of the branch to fetch or create.

            Returns:
                object: The branch object.

            """
            branch = session.query(Database.Branch).filter_by(name=name).first()

            if not branch:
                branch = Database.Branch(name=name)
                session.add(branch)
                session.commit()

            return branch

    class Version(Base):
        """Represents a version in the database.

        Attributes:
            id (int): The unique identifier for the version.
            string (str): The version string.
            branch_id (int): The identifier for the branch.

        Methods:
            fetch(session: Session, string: str, branch: object = None) -> list[object]:
                Fetches versions by string and optionally branch from the database. Raises a ValueError if no versions are found.

            fetch_or_create(session: Session, string: str, branch: object) -> object:
                Fetches a version by string and branch from the database. If the version does not exist, it creates a new version with the
                given string and branch.

        """

        __tablename__ = "versions"
        id = Column(Integer, primary_key=True)
        string = Column(String(255))
        branch_id = Column(Integer, ForeignKey("branches.id"))

        @staticmethod
        def fetch(session: Session, string: str, branch: object = None) -> list[object]:
            """Fetch versions from the database by string and optionally branch.

            Args:
                session (Session): The database session to use for the query.
                string (str): The version string to fetch.
                branch (object, optional): The branch object to filter by. Defaults to None.

            Returns:
                list[object]: The list of version objects if found.

            Raises:
                ValueError: If no versions are found in the database.

            """
            if string and branch:
                versions = session.query(Database.Version).filter_by(string=string, branch_id=branch.id).all()
            elif string:
                versions = session.query(Database.Version).filter_by(string=string).all()
            elif branch:
                versions = session.query(Database.Version).filter_by(branch_id=branch.id).all()
            else:
                msg = "At least one of 'string' / 'branch' must be specified"
                raise AttributeError(msg)

            if not versions:
                msg = f"Version {string} {f'for {branch.name} branch ' if branch else ''}not found in database"
                raise ValueError(msg)

            return versions

        @staticmethod
        def fetch_or_create(session: Session, string: str, branch: object) -> object:
            """Fetch or create a version by its string and branch.

            Args:
                session (Session): The database session to use for the query.
                string (str): The version string to fetch or create.
                branch (object): The branch object.

            Returns:
                object: The version object.

            """
            try:
                version = Database.Version.fetch(session, string, branch)[0]
            except ValueError:
                version = Database.Version(string=string, branch_id=branch.id)
                session.add(version)
                session.commit()

            return version

    class FileSizes(Base):
        """Represents file sizes in the database.

        Attributes:
            id (int): The unique identifier for the file size entry.
            device_id (int): The identifier for the device.
            file_id (int): The identifier for the file.
            version_id (int): The identifier for the version.
            value (int): The size value.

        Methods:
            fetch_or_create(session: Session, device_id: int, file_id: int, version_id: int, size_value: int) -> object:
                Fetches a file size entry by device ID, file ID, and version ID from the database. If the entry does not exist, it creates a
                new entry with the given values.

        """

        __tablename__ = "file_sizes"
        id = Column(Integer, primary_key=True)
        device_id = Column(Integer, ForeignKey("devices.id"))
        file_id = Column(Integer, ForeignKey("files.id"))
        version_id = Column(Integer, ForeignKey("versions.id"))
        value = Column(Integer)

        @staticmethod
        def fetch_or_create(session: Session, device_id: int, file_id: int, version_id: int, size_value: int) -> object:
            """Fetch or create a file size entry by device ID, file ID, and version ID.

            Args:
                session (Session): The database session to use for the query.
                device_id (int): The device ID.
                file_id (int): The file ID.
                version_id (int): The version ID.
                size_value (int): The size value.

            Returns:
                object: The file size entry object.

            """
            size_entries = session.query(Database.FileSizes).filter_by(device_id=device_id, file_id=file_id, version_id=version_id)
            size_entry = size_entries.first()
            if size_entry:
                return size_entry, False

            size_entry = Database.FileSizes(device_id=device_id, file_id=file_id, version_id=version_id, value=size_value)
            session.add(size_entry)

            return size_entry, True


def convert_human_readable(size: int, mult: int, units: list) -> tuple[float, str]:
    """Convert a size in bytes to a human-readable format.

    Args:
        size (int): The size in bytes.
        mult (int): The multiplier to use for conversion (e.g., 1024 for binary units).
        units (list): The list of units to use for conversion (e.g., ["", "k", "M", "G"]).

    Returns:
        tuple[float, str]: The converted size and the corresponding unit.

    """
    unit_index = 0

    while abs(size) >= mult:
        unit_index += 1
        size /= mult

    return size, units[unit_index]


def convert_dummy(size: int, _: str, __: list) -> tuple[float, str]:
    """Return the size as is.

    Args:
        size (int): The size in bytes.
        _ (str): Unused parameter.
        __ (bool, optional): Unused parameter. Defaults to False.

    Returns:
        tuple[float, str]: The size as a float and an empty string as the unit.

    """
    return float(size), ""


def format_size(size: int, unit: str, *, add_sign: bool = False) -> str:
    """Format a size value with the given unit.

    Args:
        size (int): The size value.
        unit (str): The unit of the size.
        add_sign (bool, optional): Whether to add a sign to the formatted size. Defaults to False.

    Returns:
        str: The formatted size string.

    """
    format_str = "{:+.2f}" if add_sign else "{:.2f}"

    return config.size_regex.sub("", format_str.format(size)) + unit


def print_line(  # noqa: PLR0913
    l_size: str,
    size_diff: str,
    r_size: str,
    r_color: bcolors,
    diff_color: bcolors,
    file: str,
    config: callable,
) -> None:
    """Print a formatted line with size information and file name.

    Args:
        l_size (str): The left size value.
        size_diff (str): The size difference value.
        r_size (str): The right size value.
        r_color (bcolors): The color for the right size value.
        diff_color (bcolors): The color for the size difference value.
        file (str): The file name.
        config (callable): The configuration object.

    """
    print(
        f"{l_size: >{config.size_width_l}} {diff_color}{size_diff:>{config.size_width}}{bcolors.ENDC} "
        f"{r_color}{r_size: >{config.size_width_r}}{bcolors.ENDC} {bcolors.OKCYAN}{file}{bcolors.ENDC}",
    )


def print_separator(config: callable, filename_len: int) -> None:
    """Print a separator line.

    Args:
        config (callable): The configuration object.
        filename_len (int): The length of the filename.

    """
    try:
        separator_length = min(filename_len, get_terminal_size().columns)
    except OSError:
        separator_length = filename_len

    print_line(
        config.separator * config.size_width_l,
        config.separator * config.size_width,
        config.separator * config.size_width_r,
        bcolors.ENDC,
        bcolors.ENDC,
        config.separator * separator_length,
        config,
    )


def print_data(  # noqa: PLR0913
    l_size: int,
    size_diff: int,
    r_size: int,
    file: str,
    config: callable,
    color: bcolors = bcolors.ENDC,
) -> None:
    """Print formatted size data for a file.

    Args:
        l_size (int): The left size value.
        size_diff (int): The size difference value.
        r_size (int): The right size value.
        file (str): The file name.
        config (callable): The configuration object.
        color (bcolors, optional): The color for the file name. Defaults to bcolors.ENDC.

    """
    if size_diff == 0:
        diff_color = bcolors.ENDC
    else:
        diff_color = bcolors.OKGREEN if size_diff < 0 else bcolors.FAIL
        size_diff = format_size(*config.convert_f(size_diff, config.unit_multiple, config.units), add_sign=True)

    l_size = format_size(*config.convert_f(l_size, config.unit_multiple, config.units)) if l_size else config.default_no_value_str
    r_size = format_size(*config.convert_f(r_size, config.unit_multiple, config.units)) if r_size else config.default_no_value_str

    print_line(l_size, size_diff, r_size, color, diff_color, file, config)


def parse_target(version_str: str) -> tuple[None | str, str]:
    """Parse the target from a version string.

    Args:
        version_str (str): The version string.

    Returns:
        tuple[None | str, str]: The target and the version string.

    """
    version_str = version_str.replace("_GPL_", "_")  # drop GPL suffix, because GPL is specified in --type
    match = re.search(r"([A-Z\d]+)_((?:R|T)_(?:(?:[A-Z\d]+)_)?(?:\d{2}\.){2,3}(?:\d+))", version_str)
    return match.group(1, 2) if match else (None, version_str)


def get_targets(args: object) -> tuple[str, str]:
    """Get the targets from the arguments.

    Args:
        args (object): The arguments object.

    Returns:
        tuple[str, str]: The old and new targets.

    """
    target1, args.old_version = parse_target(args.old_version)

    if not target1:
        return args.target, None

    target2, args.new_version = parse_target(args.new_version)

    if target1 != target2 and not args.force:
        print(f"Two different targets {target1} and {target2} in version names", end="")

        if args.target:
            print(f" - ignoring. Using explicitly specified target {args.target} instead")
            target1 = args.target
        else:
            exit_w_err(". To force a comparison between different targets, use --force")

    return target1, target2


def get_devices(db: Database, targets: list[str]) -> tuple[Database.Device, Database.Device]:
    """Get the devices from the database.

    Args:
        db (Database): The database object.
        targets (list[str]): The list of targets.

    Returns:
        tuple[Database.Device, Database.Device]: The old and new devices.

    """
    try:
        device1 = Database.Device.fetch(session=db.session, name=targets[0])
        device2 = Database.Device.fetch(session=db.session, name=targets[1]) if targets[1] else device1
    except ValueError as e:
        exit_w_err(str(e))

    return device1, device2


def check_for_multiple_versions(version: Database.Version, branch_type: str) -> None:
    """Check for multiple versions in the database.

    Args:
        version (Database.Version): The version object.
        branch_type (str): The branch type.

    Raises:
        ValueError: If multiple versions are found.

    """
    if len(version) > 1:
        exit_w_err(
            f"Version {version[0].string} exists on multiple branches: "
            f"{'\n\t'.join([''] + [v.branch for v in version])}\n"
            f"Clarify branch for this version with --{branch_type}-branch",
        )


def get_versions(args: object, db: Database) -> tuple[Database.Version, Database.Version]:
    """Get the versions from the database.

    Args:
        args (object): The arguments object.
        db (Database): The database object.

    Returns:
        tuple[Database.Version, Database.Version]: The old and new versions.

    """
    try:
        branch1 = Database.Branch.fetch(db.session, args.old_branch) if args.old_branch else None
        branch2 = Database.Branch.fetch(db.session, args.new_branch) if args.new_branch else None
        version1 = Database.Version.fetch(db.session, parse_target(args.old_version)[1], branch1)
        version2 = Database.Version.fetch(db.session, parse_target(args.new_version)[1], branch2)
    except ValueError as e:
        exit_w_err(str(e))

    check_for_multiple_versions(version1, "old")
    check_for_multiple_versions(version2, "new")

    return version1[0], version2[0]


def compare(args: object, db: Database, files_type: Database.FileTypes) -> None:
    """Compare file sizes between two firmware versions.

    Args:
        args (object): The arguments object.
        db (Database): The database object.
        files_type (Database.FileTypes): The file type object.

    """
    config.convert_f = convert_human_readable if args.human_readable else convert_dummy

    target1, target2 = get_targets(args)
    device1, device2 = get_devices(db, [target1, target2])
    version1, version2 = get_versions(args, db)

    FileSize1 = aliased(Database.FileSizes)  # noqa: N806
    FileSize2 = aliased(Database.FileSizes)  # noqa: N806

    query = (
        db.session.query(
            Database.File.name.label("filename"),
            FileSize1.value.label("version1_size"),
            FileSize2.value.label("version2_size"),
        )
        .outerjoin(FileSize1, (Database.File.id == FileSize1.file_id) & (FileSize1.version_id == version1.id))
        .outerjoin(FileSize2, (Database.File.id == FileSize2.file_id) & (FileSize2.version_id == version2.id))
        .filter(
            or_(FileSize1.value.isnot(None), FileSize2.value.isnot(None)),
            FileSize1.device_id == device1.id,
            FileSize2.device_id == device2.id,
            Database.File.file_type_id == files_type.id,
        )
    )
    results = query.all()

    config.size_width_l = max(config.size_width, len(version1.string))
    config.size_width_r = max(config.size_width, len(version2.string))
    print_line(
        "\n" + version1.string,
        "Diff",
        version2.string,
        bcolors.ENDC,
        bcolors.ENDC,
        "Filename",
        config,
    )
    print_separator(config, max([len(result.filename) for result in results] + [len("Filename")]))

    for result in results:
        if not (result.version1_size and args.all) and result.version1_size == result.version2_size:
            continue

        size_diff = result.version2_size - result.version1_size

        color = bcolors.WARNING + bcolors.BOLD if size_diff > result.version1_size * 0.5 else bcolors.ENDC

        print_data(result.version1_size, size_diff, result.version2_size, result.filename, config, color)


def collect_files(root_dir: str, file_list_type: str) -> str:
    """Collect file statistics from the specified directory.

    Args:
        root_dir (str): The root directory to collect files from.
        file_list_type (str): The type of file list to collect.

    Returns:
        str: The collected file statistics.

    """
    if file_list_type == "ipk":
        find_command = ["find", root_dir, "-name", "*.ipk", "-exec", "du", "--all", "--bytes", "{}", ";"]
        perl_command = ["perl", "-p", "-e", "s/^(\\d+\\s+).*\\//\\1/"]
        find_process = Popen(find_command, stdout=PIPE)  # noqa: S603
        perl_process = Popen(perl_command, stdin=find_process.stdout, stdout=PIPE)  # noqa: S603
        find_process.stdout.close()
        output, _ = perl_process.communicate()
        return output.decode()

    files_stats = (
        run(  # noqa: S603
            ["du", "--all", "--bytes", "."],  # noqa: S607
            cwd=root_dir,
            stdout=PIPE,
            text=True,
            check=True,
        ).stdout
        + "\n"
    )
    if file_list_type == "gpl":
        return files_stats

    find_command = ["find", str(Path(root_dir).parent), "-type", "f", "-name", "root.squashfs"]
    f_squashfs = run(find_command, stdout=PIPE, text=True, check=True).stdout.splitlines()[0]  # noqa: S603
    find_command = ["find", str(Path(f_squashfs).parent), "-maxdepth", "1", "-type", "f", "-name", "*.bin"]
    f_kernel = run(find_command, stdout=PIPE, text=True, check=True).stdout.splitlines()[0]  # noqa: S603

    return (
        f"{Path(f_kernel).stat().st_size}\t{Path(f_kernel).name}\n"
        f"{Path(f_squashfs).stat().st_size}\t{Path(f_squashfs).name}\n" + files_stats
    )


def drop_vuci_suffix(filename: str) -> str:
    """Drop the VUCI suffix from the filename.

    Args:
        filename (str): The filename to process.

    Returns:
        str: The filename without the VUCI suffix.

    """
    return re.sub(r"(\/www\/assets.*?)(?:-\d{2,4}){3}-[\da-f]{7}(\.(?:js|css)\.gz)", r"\1\2", filename)


def save(args: object, db: Database, files_type: Database.FileTypes) -> None:
    """Save file size information to the database.

    Args:
        args (object): The arguments object.
        db (Database): The database object.
        files_type (Database.FileTypes): The file type object.

    """
    root_dir = quote(args.info_path)
    if Path(root_dir).is_file():
        with Path(root_dir).open() as file:
            files_stats = file.read()
    elif Path(root_dir).is_dir():
        files_stats = collect_files(root_dir, args.type)
    else:
        exit_w_err(f"{root_dir}: no such file or directory")

    target, version_str = parse_target(args.version)
    device = Database.Device.fetch_or_create(session=db.session, name=target if target else args.target)
    branch = Database.Branch.fetch_or_create(session=db.session, name=args.branch)
    version = Database.Version.fetch_or_create(session=db.session, string=version_str, branch=branch)

    for file_info in files_stats.split("\n"):
        if not file_info:
            continue

        file_size, file_name = file_info.split("\t")
        file_size = int(file_size)
        file_name = drop_vuci_suffix(file_name) if file_name.startswith("/www/assets/") else file_name

        file = Database.File.fetch_or_create(session=db.session, name=file_name, f_type_id=files_type.id)
        size, is_new = Database.FileSizes.fetch_or_create(
            session=db.session,
            device_id=device.id,
            file_id=file.id,
            version_id=version.id,
            size_value=file_size,
        )

        if not is_new and size.value != file_size:
            print(
                f"Warning: File '{file_name}' already has a size of {size.value} for version {version.string} "
                f"in the database. New size: {file_size}",
            )
            size.size = file_size

    db.session.commit()
    print(
        f"Info about {device.name.upper()} {files_type.name} files for version {version.string} "
        f"on {branch.name} branch written to database",
    )


def list_versions(args: object, db: Database, files_type: Database.FileTypes) -> None:  # noqa: ARG001
    """List available versions for a branch.

    Args:
        args (object): The arguments object.
        db (Database): The database object.
        files_type (Database.FileTypes): The file type object.

    """
    try:
        [print(v.string) for v in Database.Version.fetch(db.session, None, Database.Branch.fetch(db.session, args.branch))]
    except ValueError as e:
        exit_w_err(str(e))


def getenv_or_default(env_variable: str) -> str:
    """Retrieve the value of an environment variable or return a default value.

    Args:
        env_variable (str): The name of the environment variable.

    Returns:
        str: The value of the environment variable.

    Raises:
        EnvironmentError: If the environment variable is not found and no default value is specified.

    """
    value = getenv(env_variable)
    if value:
        return value

    defaults = {
        "ROM_DIFF_DB_USER": "reader",
        "ROM_DIFF_DB_PASSWORD": "Kaunastlt1!",
        "ROM_DIFF_DB_HOST": "10.65.2.9",
        "ROM_DIFF_DB_PORT": "3306",
        "ROM_DIFF_DB_NAME": "files_sizes",
    }

    if env_variable in defaults:
        return defaults[env_variable]

    print(f"Failed to get '{env_variable}' from the environment and no default value specified!")
    raise EnvironmentError  # noqa: UP024


def parse_args() -> object:
    """Parse command-line arguments.

    Returns:
        object: The parsed arguments object.

    """
    parser = argparse.ArgumentParser(
        description="Show / collect information about size differences of FW / SDK / IPK files between FW versions",
    )

    parser.add_argument(
        "-t",
        "--type",
        choices=config.file_list_types,
        help="Type of file lists to perform actions on (default - fw)",
        default="fw",
    )
    parser.add_argument("--gpl", action="store_true", help="Shorthand for --type=gpl")

    parser.add_argument(
        "--target",
        help=(
            "Compilation target (default - currently selected target in .config). "
            "Targets that are specified in version strings take precedence (e.g. RUTX_T_DEV_...). "
            "For a list of available targets, use './select.sh'"
        ),
        default=re.sub(
            r"x{2,}$",
            "",
            run(
                [
                    "grep",
                    "-oP",
                    r"^CONFIG_TARGET_(?:MULTI_PROFILE_NAME|PROFILE)=\"DEVICE_teltonika_\K\S+(?=\")",
                    f"{config.top_dir}/.config",
                ],
                stdout=PIPE,
                text=True,
                check=True,
            ).stdout.strip(),
            flags=re.MULTILINE,
        ),
    )

    subparsers = parser.add_subparsers(title="actions")

    parser_compare = subparsers.add_parser(
        "compare",
        aliases=["c"],
        help="Compare FW file differences between versions",
    )
    parser_compare.add_argument("-a", "--all", action="store_true", help="Don't skip files that are the same size")
    parser_compare.add_argument(
        "-H",
        "--human-readable",
        action="store_true",
        help="Print sizes in human readable format (e.g., 1k 2.5M 2G)",
    )
    parser_compare.add_argument(
        "-f",
        "--force",
        action="store_true",
        help="Force comparison between different targets",
    )
    parser_compare.add_argument(
        "--old-branch",
        help="Branch to take old_version from (if there are same versions on different branches)",
    )
    parser_compare.add_argument(
        "--new-branch",
        help="Branch to take new_version from (if there are same versions on different branches)",
    )
    parser_compare.add_argument(
        "old_version",
        help="Old version to use as a base for comparison",
    )
    parser_compare.add_argument(
        "new_version",
        help="Pretty self-explanatory",
    )
    parser_compare.set_defaults(func=compare)

    parser_save = subparsers.add_parser("save", aliases=["s"], help="Save information about the files' sizes")
    parser_save.add_argument(
        "--branch",
        help="Git branch of the files (default - currently checked-out branch)",
        default=run(  # noqa: S603
            ["git", "-C", str(config.top_dir), "rev-parse", "--abbrev-ref", "HEAD"],  # noqa: S607
            stdout=PIPE,
            text=True,
            check=True,
        ).stdout.strip(),
    )

    parser_save.add_argument(
        "--version",
        help="FW version of the files",
        default=re.sub(
            r"^[^_]+_",
            "",
            run([f"{config.script_dir}/get_tlt_version.sh"], stdout=PIPE, text=True, check=True).stdout,  # noqa: S603
            flags=re.MULTILINE,
        ),
    )
    parser_save.add_argument(
        "info_path",
        help="A root directory of the file tree to save, like build_dir/target-*/root-*",
    )
    parser_save.set_defaults(func=save)

    parser_list = subparsers.add_parser("list", aliases=["l"], help="List versions available for branch")
    parser_list.add_argument(
        "branch",
        help="Branch to list versions for",
    )
    parser_list.set_defaults(func=list_versions)

    return parser.parse_args()


def main() -> None:
    """Parse arguments and execute the appropriate action."""
    args = parse_args()
    db = Database(*[getenv_or_default("ROM_DIFF_" + env_var) for env_var in ["DB_USER", "DB_PASSWORD", "DB_HOST", "DB_PORT", "DB_NAME"]])

    if args.gpl:
        args.type = "gpl"

    files_type = Database.FileTypes.fetch_or_create(session=db.session, name=args.type)

    args.func(args, db, files_type)


if __name__ == "__main__":
    main()
