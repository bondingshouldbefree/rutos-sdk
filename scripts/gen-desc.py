#!/usr/bin/env python3

import sys
import os
import subprocess
import json
import re
import argparse
from os import path
from subprocess import Popen

list_profiles = list()
list_features = list()
list_packages = list()
dump_list = False

def empty_none_value(value):
    if value is None:
        return ''

    return value

def is_match(regex, text):
    return re.compile(regex).search(text) is not None

def type_cast(value):
    if isinstance(value, str) and value.isdigit():
        return int(value.strip())
    return value.strip()

def recursive_insert(dct, keys, value):
    if len(keys) == 1:
        if ';' in value:
            value = value.split(';')
            stripped_values = [v.strip() for v in value if v]

            if keys[0] in dct and isinstance(dct[keys[0]], list):
                current = dct[keys[0]]
                dct[keys[0]] = list(set(current + stripped_values))
            else:
                dct[keys[0]] = stripped_values
        else:
            dct[keys[0]] = type_cast(value)
    else:
        if keys[0] not in dct or not isinstance(dct[keys[0]], dict):
            dct[keys[0]] = {}
        recursive_insert(dct[keys[0]], keys[1:], value)

def find_pkg_by_name(name):
    for pkg in list_packages:
        if pkg.name == name:
            return pkg

    return None

def append_or_insert_arr(array, target_kv):
    for item in array:
        if item['key'] == target_kv['key'] and item.get('type', None) == target_kv.get('type', None):
            if target_kv['value'][0] == '\\' and target_kv['value'][1] != '\\':
                item['value'] += target_kv['value'][1:]
            else:
                item['value'] += ' ' + target_kv['value']
            return

    array.append(target_kv)

class Target:
    def __init__(self, name):
        self.name = name
        self.features = []

    def target(self):
        data = self.name.split('/')
        return data[0]

    def subtarget(self):
        data = self.name.split('/')

        if len(data) == 1:
            return 'none'

        return data[1]

    def parse(self, file):
        for l in file:
            if is_match('^@@$', l):
                break
            elif is_match('^Target-Features: ', l):
                self.features = set(l[17:-1].split())

class Profile:
    def __init__(self, profile, target):
        self.name = 'Unknown'
        self.target = target
        self.profile = profile
        self.hw = {}
        self.hw_tooltip = {}
        self.regulatory = {}
        self.regulatory_tooltip = {}
        self.technical = {}
        self.technical_tooltip = {}
        self.conf = {}
        self.features = []
        self.features_profile = []
        self.cached_packages = {}

    def recursive_insert(self, dct, keys, value):
        kname = keys[0].replace('_', ' ')
        if len(keys) == 1:
            dct[kname] = value
        else:
            if kname not in dct:
                dct[kname] = {}
            self.recursive_insert(dct[kname], keys[1:], value)

    def convert_to_array_format(self, dct, tooltip_dct={}):
        result = []
        for key, value in dct.items():
            entry = {"title": key}
            if isinstance(value, dict):
                entry["detail"] = [{"key": subkey, "value": subvalue} for subkey, subvalue in value.items()]
            else:
                entry["detail"] = [value]
            entry["tooltip"] = []
            result.append(entry)
        for key, value in tooltip_dct.items():
            entry = next((item for item in result if item["title"] == key), None)
            if entry is None:
                entry = {"title": key, "detail": [], "tooltip": []}
                result.append(entry)
            if isinstance(value, dict):
                for subkey, subvalue in value.items():
                    if isinstance(subvalue, dict):
                        entry["tooltip"].append({"key": subkey, "value": subvalue['value'], "type": subvalue['type']})
                    else:
                        entry["tooltip"].append({"key": subkey, "value": subvalue})
            else:
                entry["tooltip"] = [value]
        return result

    def parse_tooltip(self, key_parts, value):
        if key_parts[-1] != 'Tooltip' and (len(key_parts) < 2 or key_parts[-2] != 'Tooltip'):
            return None

        tooltip_type = 'key'
        if key_parts[-1] == 'Tooltip':
            key_parts.pop()
        elif len(key_parts) > 1 and key_parts[-2] == 'Tooltip':
            key_parts.pop(-2)

        if key_parts and (key_parts[-1] == 'Value' or key_parts[-1] == 'Key'):
            tooltip_type = key_parts[-1].lower()
            key_parts.pop()

        return {'type': tooltip_type, 'value': value}

    def parse(self, file):
        for l in file:
            if is_match('^@@$', l):
                break
            elif is_match('^Target-Profile-Name:', l):
                self.name = l[21:-1]
            elif is_match('^Target-Profile-Features: ', l):
                self.features_profile = set(l[25:-1].split())
                self.features = self.features_profile | self.target.features
            elif 'Target-Profile-HARDWARE-' in l:
                data = l.strip()[24:].split(': ', 1)
                if len(data) < 2:
                    continue

                key_parts = re.split(r'(?<!\\)-', data[0])
                key_parts = [part.replace('\\-', '-') for part in key_parts]
                tooltip = self.parse_tooltip(key_parts, data[1])
                if tooltip is not None:
                    self.recursive_insert(self.hw_tooltip, key_parts, tooltip)
                    continue
                self.recursive_insert(self.hw, key_parts, data[1])
            elif 'Target-Profile-REGULATORY-' in l:
                data = l.strip()[26:].split(': ', 1)
                if len(data) < 2:
                    continue

                key_parts = re.split(r'(?<!\\)-', data[0])
                key_parts = [part.replace('\\-', '-') for part in key_parts]
                tooltip = self.parse_tooltip(key_parts, data[1])
                if tooltip is not None:
                    self.recursive_insert(self.regulatory_tooltip, key_parts, tooltip)
                    continue
                self.recursive_insert(self.regulatory, key_parts, data[1])
            elif 'Target-Profile-TECHNICAL-' in l:
                data = l.strip()[25:].split(': ', 1)
                if len(data) < 2:
                    continue

                key_parts = re.split(r'(?<!\\)-', data[0])
                key_parts = [part.replace('\\-', '-') for part in key_parts]
                tooltip = self.parse_tooltip(key_parts, data[1])
                if tooltip is not None:
                    self.recursive_insert(self.technical_tooltip, key_parts, tooltip)
                    continue
                self.recursive_insert(self.technical, key_parts, data[1])

        self.hw = self.convert_to_array_format(self.hw, self.hw_tooltip)
        self.regulatory = self.convert_to_array_format(self.regulatory, self.regulatory_tooltip)
        self.technical = self.convert_to_array_format(self.technical, self.technical_tooltip)

    def parse_expr(self, expr):
        pattern = re.compile(r'if\s+(.*)', re.DOTALL)
        match = pattern.match(expr)

        if not match:
            raise ValueError(f'Invalid detail line format: {expr}')

        condition_expr = match.group(1)

        if condition_expr:
            tokens = re.findall(r'\w+|&&|\|\||!|\(|\)', condition_expr)
        else:
            tokens = []

        return tokens

    def evaluate_expr(self, tokens):
        def eval_token(token):
            if token in self.conf:
                return self.conf[token] in {True, 'm'}
            return False

        def eval_not(token):
            return not eval_token(token)

        def eval_and(tokens):
            return all(self.evaluate_expr(t) for t in tokens)

        def eval_or(tokens):
            return any(self.evaluate_expr(t) for t in tokens)

        stack = []
        i = 0
        while i < len(tokens):
            token = tokens[i]
            if token == '&&':
                stack.append('&&')
            elif token == '||':
                stack.append('||')
            elif token == '!':
                stack.append(eval_not(tokens[i+1]))
                i += 1
            elif token == '(':
                sub_expr = []
                paren_count = 1
                i += 1
                while i < len(tokens):
                    if tokens[i] == '(':
                        paren_count += 1
                    elif tokens[i] == ')':
                        paren_count -= 1
                        if paren_count == 0:
                            break
                    sub_expr.append(tokens[i])
                    i += 1
                stack.append(self.evaluate_expr(sub_expr))
            else:
                stack.append(eval_token(token))
            i += 1

        result = stack[0]
        i = 1
        while i < len(stack):
            if stack[i] == '&&':
                result = result and stack[i+1]
            elif stack[i] == '||':
                result = result or stack[i+1]
            i += 2

        return result

    def prepare_dotconfig(self):
        f = open('.config', 'w')

        f.write(f'CONFIG_TARGET_{self.target.target()}=y\n')
        f.write(f'CONFIG_TARGET_{self.target.target()}_{self.target.subtarget()}=y\n')
        f.write(f'CONFIG_TARGET_{self.target.target()}_{self.target.subtarget()}_{self.profile}=y\n')

        f.close()

        Popen('./scripts/auto-exec.sh ./scripts/config/conf --defconfig .config Config.in',
            shell=True, stdout=subprocess.DEVNULL).wait()

    def read_config(self):
        with open('.config', 'r') as config_file:
            for line in config_file:
                line = line.strip()
                if line.endswith('is not set'):
                    self.conf[line.split(' ')[1].split('CONFIG_')[1]] = False
                elif '=' in line:
                    option, value = line.split('=', 1)
                    self.conf[option.split('CONFIG_')[1]] = True if value == 'y' else value

    def fetch_features(self):
        self.features = []

        for f in list_features:
            if not f.name in self.conf or self.conf[f.name] is False:
                continue

            new_detail = []
            new_tooltip = []

            for d in f.detail:
                new_item = {'key': d['key'], 'value': d['value']}

                if not 'expr' in d or not d['expr']:
                    append_or_insert_arr(new_detail, new_item)
                    continue

                expr = self.parse_expr(d['expr'])
                if self.evaluate_expr(expr):
                    append_or_insert_arr(new_detail, new_item)
            for t in f.tooltip:
                new_item = {'key': t['key'], 'value': t['value'], 'type': t['type']}

                if not 'expr' in t or not t['expr']:
                    append_or_insert_arr(new_tooltip, new_item)
                    continue

                expr = self.parse_expr(t['expr'])
                if self.evaluate_expr(expr):
                    append_or_insert_arr(new_tooltip, new_item)

            f.detail = new_detail
            f.tooltip = new_tooltip
            f.external = (self.conf[f.name] == 'm')

            self.features.append(f)

    def fetch_packages(self):
        for key, value in self.conf.items():
            if not key.startswith('PACKAGE_') or not value:
                continue

            pkg_name = key[8:].strip()
            if not pkg_name:
                continue

            if pkg_name not in self.cached_packages:
                self.find_package_deps([pkg_name])

    def find_package_deps(self, deps):
        for d in deps:
            if d in self.cached_packages:
                continue

            pkg = find_pkg_by_name(d)
            if pkg is None:
                continue

            deps = []
            for dep in pkg.deps:
                expr = dep['expr']
                name = dep['name']

                if not name:
                    continue

                if expr:
                    tokens = re.findall(r'\w+|&&|\|\||!|\(|\)', expr)
                    if self.evaluate_expr(tokens):
                        deps.append(name)
                else:
                    deps.append(name)

            info = {
                'name': pkg.name,
                'title': pkg.title,
                # 'maintainer': pkg.maint,
                'description': pkg.desc,
                # 'detail': pkg.detail,
                'depends': deps,
            }
            self.find_package_deps(deps)
            self.cached_packages[pkg.name] = info

    def json(self, descriptions_only=False):
        data = {
            "name": self.name,
            "hwinfo": list(self.features_profile),
            "target": {"name": self.target.target(), "subtarget": self.target.subtarget(), "profile": self.profile},
            "hardware": self.hw,
            "software": [],
            "technical": self.technical,
            "regulatory": self.regulatory,
            "packages": []
        }

        if descriptions_only:
            del data["target"]
            del data["hwinfo"]
            del data["packages"]

        self.prepare_dotconfig()
        self.read_config()
        self.fetch_features()
        self.fetch_packages()

        data["packages"] = list(self.cached_packages.keys())

        data["software"] = dump_features(self.features, descriptions_only)

        return data

def run_metadata_info(*args):
    command = './scripts/target-metadata.pl '
    command += ' '.join(args)
    return subprocess.run(command, shell=True, capture_output=True, text=True).stdout.strip()

def initialize_targets(targetDevice=None, targetFamily=None):
    ti = 'tmp/.targetinfo'
    devlist = None

    print('Initializing targets...')

    if not path.exists(ti):
        print('Target info does not exist, running defconfig...')
        Popen('make defconfig', shell=True).wait()

    if not path.exists(ti):
        print('Unable to initialize targets due to missing targetinfo data!')
        exit(1)

    if targetFamily is not None:
        res = run_metadata_info('target', 'tmp/.targetinfo', targetFamily)
        match = re.search(r'DEVICE_PROFILE=(DEVICE_teltonika_\S+)', res)
        if match:
            familyProfile = match.group(1).replace("DEVICE_", "")
            print(f'Found family profile: {familyProfile}')
        else:
            return

        res = run_metadata_info('option', 'tmp/.targetinfo', familyProfile, 'included_devices')
        if not res:
            # use family profile for backwards compatibility
            devlist = [ familyProfile ]
            print(f'Unable to find family devices, using family profile: {", ".join(devlist)}')
        else:
            devlist = res.split()
            print(f'Found family devices: {", ".join(devlist)}')

    f = open(ti, 'r')
    target = None

    for line in f:
        if is_match('^Target: ', line):
            target = Target(line[8:-1])
            target.parse(f)
        elif is_match('^Target-Profile:', line):
            if targetDevice is not None:
                if targetDevice in line[33:-1]:
                    profile = Profile(line[16:-1], target)
                    profile.parse(f)
                    list_profiles.append(profile)
                    break
            elif targetFamily is not None:
                if line[23:-1] in devlist:
                    profile = Profile(line[16:-1], target)
                    profile.parse(f)
                    list_profiles.append(profile)
            else:
                profile = Profile(line[16:-1], target)
                profile.parse(f)
                list_profiles.append(profile)

    f.close()

class Feature:
    def __init__(self, name):
        self.name = empty_none_value(name)
        self.title = ''
        self.maintainer = ''
        self.label = 'Utilities'
        self.external = False
        self.packages = []
        self.detail = []
        self.tooltip = []

    def parse_extra(self, line, expr):
        l = line.strip()

        if not l:
            return None

        key, value = '', ''

        colon_index = l.find(':')
        if colon_index > 0 and l[colon_index - 1] != '\\':
            key, value = l.split(':', 1)
            key = key.strip()
            value = value.strip()
        else:
            key = self.title
            value = l.replace('\\:', ':').strip()

        return {'key': key, 'value': value, 'expr': expr}

    def parse(self, file):
        tooltip_parse = False
        tooltip_expr_parse = False
        tooltip_expr_str = ''
        tooltip_type = ''
        detail_parse = False
        detail_expr_parse = False
        detail_expr_str = ''

        while True:
            position = file.tell()
            l = file.readline()

            if not l:
                break

            if is_match('^config ', l):
                file.seek(position)
                break
            elif is_match('^endmenu', l):
                tooltip_parse = False
                detail_parse = False
                detail_expr_parse = False
                tooltip_expr_parse = False
            elif is_match('^\tbool ', l) or is_match('^\ttristate ', l):
                tooltip_parse = False
                detail_parse = False
                detail_expr_parse = False
                tooltip_expr_parse = False
                tmp = l.split(' ', 1)

                if len(tmp) >= 2:
                    self.title = tmp[1][:-1].strip('"')
            elif is_match('^\tselect ', l) or is_match('^\timply ', l):
                tooltip_parse = False
                detail_parse = False
                detail_expr_parse = False
                info = l.split(' ', 2)

                if 'PACKAGE_' in info[1]:
                    self.packages.append(info[1][8:].strip())
                else:
                    self.packages.append(info[1].strip())
            elif is_match('^\tdefault ', l):
                tooltip_parse = False
                detail_parse = False
                detail_expr_parse = False
                tooltip_expr_parse = False
            elif is_match('^\tmaintainer ', l):
                tooltip_parse = False
                detail_parse = False
                self.maintainer = l[13:-2]
            elif is_match('^\tlabel ', l):
                tooltip_parse = False
                detail_parse = False
                self.label = l[8:-2]
            elif is_match('^\tdepends on ', l):
                tooltip_parse = False
                detail_parse = False
                detail_expr_parse = False
                tooltip_expr_parse = False
            elif is_match('^\tdetail', l):
                tooltip_parse = False
                detail_parse = True
                tooltip_expr_parse = False
                if 'detail if ' in l:
                    detail_expr_str = l[7:].strip()
                    if l[:-1].strip().endswith('\\'):
                        detail_expr_parse = True
                        detail_expr_str = detail_expr_str[:-2]
                else:
                    detail_expr_str = ''
            elif is_match('^\ttooltip', l):
                tooltip_parse = True
                detail_parse = False
                detail_expr_parse = False
                match = re.match(r'^\ttooltip(?:\s+([^\s]+))?(?:\s+(if\s+.+))?$', l)
                tooltip_target = (match.group(1) or '').strip()
                tooltip_expr_str = (match.group(2) or '').strip()

                if tooltip_target in ['key', 'value']:
                    tooltip_type = tooltip_target
                else:
                    tooltip_type = 'key'

                if tooltip_expr_str != '':
                    if l[:-1].strip().endswith('\\'):
                        tooltip_expr_parse = True
                        tooltip_expr_str = tooltip_expr_str[:-2]
            elif l.lstrip().startswith('#'):
                continue
            else:
                if detail_parse is True:
                    l = l.strip()

                    if not l:
                        continue

                    if detail_expr_parse:
                        detail_expr_str += ' ' + l.strip()
                        if not l[:-1].strip().endswith('\\'):
                            detail_expr_parse = False
                        continue

                    parsed = self.parse_extra(l, detail_expr_str)
                    if parsed is not None:
                        self.detail.append(parsed)
                elif tooltip_parse is True:
                    l = l.strip()

                    if not l:
                        continue

                    if tooltip_expr_parse:
                        tooltip_expr_str += ' ' + l.strip()
                        if not l[:-1].strip().endswith('\\'):
                            detail_expr_parse = False
                        continue

                    parsed = self.parse_extra(l, tooltip_expr_str)
                    if parsed is not None:
                        parsed['type'] = tooltip_type
                        self.tooltip.append(parsed)

def initialize_features():
    confs = [
        'config/Config-tlt.in',
        'target/Config.in'
    ]

    print('Initializing features...')

    for c in confs:
        f = open(c)

        while True:
            line = f.readline()

            if not line:
                break

            if is_match('^config ', line):
                feature = Feature(line[7:-1])
                feature.parse(f)

                new_detail = []
                new_tooltip = []

                for d in feature.detail:
                    if 'expr' in d and d['expr']:
                        new_detail.append(d)
                        continue
                    new_item = {'key': d['key'], 'value': d['value']}
                    append_or_insert_arr(new_detail, new_item)
                for t in feature.tooltip:
                    if 'expr' in t and t['expr']:
                        new_tooltip.append(t)
                        continue
                    new_item = {'key': t['key'], 'value': t['value'], 'type': t['type']}
                    append_or_insert_arr(new_tooltip, new_item)

                feature.detail = new_detail
                feature.tooltip = new_tooltip

                list_features.append(feature)

        f.close()

def dump_features(data, descriptions_only=False, dump_list=False):
    features_dict = {}
    features_list = []

    for f in data:
        if descriptions_only and not f.title:
            continue

        if f.label not in features_dict:
            entry = {
                "title": f.label,
                "feature": f.name,
                "detail": [],
                "tooltip": [],
                "features": [],
            }

            if descriptions_only:
                del entry["feature"]
                del entry["features"]

            features_dict[f.label] = entry
            features_list.append(entry)

        feature_entry = features_dict[f.label]
        if not feature_entry:
            continue

        for item in f.detail:
            if not item['key'] or not item['value']:
                continue

            detail = {
                'key': item['key'],
                'value': item['value'],
            }

            if not descriptions_only:
                detail['feature'] = f.name

            feature_entry['detail'].append(detail)

        for item in f.tooltip:
            feature_entry["tooltip"].append({'key': item['key'], 'value': item['value'], 'type': item['type']})

        if not descriptions_only:
            feature = {
                "name": f.name,
                "maintainer": f.maintainer,
                "external": f.external,
                "packages": list()
            }

            for i in f.packages:
                pkg = find_pkg_by_name(i)

                if pkg is None:
                    continue

                feature["packages"].append(pkg.name)
            feature_entry['features'].append(feature)

    if dump_list:
        return features_list

    return [item for item in features_list if len(item["detail"]) > 0]

class Package:
    def __init__(self, name):
        self.name = name
        self.title = ''
        self.desc = ''
        self.detail = ''
        self.maint = ''
        self.deps = []

    def parse_dep_info(self, line):
        deps = line.split()
        parsed = []

        for d in deps:
            expr = ''
            name = d

            if '+' in name[0]:
                name = name[1:]

            if ':' in name:
                expr, name = name.split(':', 1)

            if not expr and '@' in name[0]:
                expr = name
                name = ''

            parsed.append({'expr': expr, 'name': name})

        return parsed

    def parse(self, file):
        detail_parse = False
        help_parse = False

        for l in file:
            if is_match('^@@$', l):
                break
            elif is_match('^Title: ', l):
                self.title = l[7:-1]
            elif is_match('^Maintainer: ', l):
                self.maint = l[12:-1]
            elif is_match('^Detail-Description: ', l):
                tmp = l[20:-1].strip()
                if tmp == self.title:
                    continue
                detail_parse = True
                self.detail = tmp
            elif is_match('^Description: ', l):
                tmp = l[13:-1].strip()
                if tmp == self.title:
                    continue
                self.desc = tmp
                help_parse = True
                detail_parse = False
            elif is_match('^Depends: ', l):
                self.deps = self.parse_dep_info(l[9:-1])
            else:
                if help_parse is True:
                    self.desc = self.desc + l
                elif detail_parse is True:
                    self.detail = self.detail + l

def initialize_packageinfo():
    print('Initializing packageinfo...')

    for file in os.listdir('tmp/info'):
        if ".packageinfo-" not in file:
            continue

        f = open(f'tmp/info/{file}')

        for line in f:
            if is_match('^Package: ', line):
                pkg = Package(line[9:-1])
                pkg.parse(f)
                list_packages.append(pkg)

        f.close()


def generate_device_features(dump=False, dump_packages=False, descriptions_only=False, target=None, family=None):
    default_dir='out'
    default_name='features.json'
    dump_list = False
    json_data = None

    print('Generating device features...')

    if dump:
        print('Dumping all possible device features.')
        dump_list = True
    if dump_packages:
        print('Dumping all available packages.')
        default_name = 'packages.json'
    if target:
        print(f'Generating features for target device: {target}')
        default_name = f'{target}.json'
    if family:
        print(f'Generating features for device family: {family}')
        default_name = f'{family}.json'

    if not dump_list and not dump_packages:
        initialize_targets(targetDevice=target, targetFamily=family)

    initialize_features()
    initialize_packageinfo()

    if not os.path.exists(default_dir):
        os.makedirs(default_dir)

    # prepare for defconfig generation
    print('Initializing tmpinfo...')
    Popen('make prepare-tmpinfo', shell=True, stdout=subprocess.DEVNULL).wait()

    if dump_packages:
        json_data = []

        for pkg in list_packages:
            info = {
                'name': pkg.name,
                'title': pkg.title,
                # 'maintainer': pkg.maint,
                'description': pkg.desc,
                # 'detail': pkg.detail,
                'depends': [dep['name'] for dep in pkg.deps if dep['name']],
            }
            json_data.append(info)
    elif dump_list:
        json_data = dump_features(list_features, descriptions_only, dump_list)
    else:
        if family:
            json_data = []

        for p in list_profiles:
            print(f'Generating {p.name}...')

            if target:
                json_data = p.json(descriptions_only)
                break

            json_data.append(p.json(descriptions_only))

    if len(json_data) == 0:
        print('Unable to generate json data!')
        print('Target, family is invalid or project files are corrupted!')
        return

    default_path = os.path.join(default_dir, default_name)
    with open(default_path, 'w') as file:
        json.dump(json_data, file, indent=2, ensure_ascii=False)

    print(f'Data written to {default_path} path.')

def main():
    parser = argparse.ArgumentParser(description='Generate device features.')
    parser.add_argument("--descriptions-only", action="store_true", help="Generate only descriptions of features")

    group = parser.add_mutually_exclusive_group()
    group.add_argument('--dump', action='store_true', help='Generate all possible device features')
    group.add_argument('--dump-packages', action='store_true', help='Dump all available packages')
    group.add_argument('--target', type=str, help='Generate device features for a specific target device')
    group.add_argument('--family', type=str, help='Generate device features for a specific device family')

    args = parser.parse_args()

    if not any([args.dump, args.dump_packages, args.target, args.family]):
        parser.print_help()
        sys.exit(1)

    generate_device_features(args.dump, args.dump_packages, args.descriptions_only, args.target, args.family)


if __name__ == '__main__':
    main()
