from pathlib import Path
import subprocess
import sys
import yaml
from jinja2 import Environment, FileSystemLoader

root = Path(__file__).resolve().parent.parent
inv_file = root / (sys.argv[1] if len(sys.argv) > 1 else 'inventaire/vms.yaml')
inventory = yaml.safe_load(inv_file.read_text())

env = Environment(loader=FileSystemLoader(root / 'templates'),
                  trim_blocks=True, lstrip_blocks=True, autoescape=False)
template = env.get_template('user_data.j2')
net_template = env.get_template('network_config.j2')
key = Path.home().joinpath('.ssh/bd2c_tp2.pub').read_text().strip()

for vm in inventory['vms']:
    profile = yaml.safe_load((root / 'profils' / f"{vm['profile']}.yaml").read_text())
    target = root / 'output' / vm['name']
    target.mkdir(parents=True, exist_ok=True)
    files = ['user-data', 'meta-data']
    (target / 'user-data').write_text(template.render(**vm, **profile, ssh_public_key=key))
    (target / 'meta-data').write_text(
        f"instance-id: iid-bd2c-{vm['hostname']}\nlocal-hostname: {vm['hostname']}\n")
    if 'ip' in vm:
        (target / 'network-config').write_text(net_template.render(**vm))
        files.append('network-config')
    subprocess.run(['genisoimage', '-quiet', '-output', 'seed.iso', '-volid', 'cidata',
                    '-joliet', '-rock', *files], cwd=target, check=True)
    print(target)
