#!/usr/bin/env python3

base_path = "package/base-files/files/etc/"

passwd_lines = list(map(lambda line: line.split(":"), open(base_path + "passwd", "r").readlines()))
passwd_lines.sort(key=lambda line: int(line[2]))  # uid
passwd_users = [line[0] for line in passwd_lines]
passwd_text = "".join([":".join(line) for line in passwd_lines])
open(base_path + "passwd", "w").write(passwd_text)

shadow_lines = list(map(lambda line: line.split(":"), open(base_path + "shadow", "r").readlines()))
shadow_lines.sort(key=lambda line: passwd_users.index(line[0]))  # uid
shadow_text = "".join([":".join(line) for line in shadow_lines])
open(base_path + "shadow", "w").write(shadow_text)

group_lines = list(map(lambda line: line.split(":"), open(base_path + "group", "r").readlines()))
group_lines.sort(key=lambda line: int(line[2]))  # gid
for line in group_lines:
	group = line[0]
	users = line[3].split(",")
	users[-1] = users[-1][:-1]  # remove trailing newline
	if len(users) == 1 and users[0] == "":
		users = []
	if group in users:
		users.remove(group)
	users.sort()  # alphabetical
	line[3] = ",".join(users)
group_text = "\n".join([":".join(line) for line in group_lines])
open(base_path + "group", "w").write(group_text)
