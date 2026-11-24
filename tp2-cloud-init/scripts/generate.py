from pathlib import Path
import subprocess
import yaml
from jinja2 import Environment, FileSystemLoader

root = Path(__file__).resolve().parent.parent
inventory = yaml.safe_load((root / 'inventaire/vms.yaml').read_text())
env = Environment(loader=FileSystemLoader(root / 'templates'),
                  trim_blocks=True, lstrip_blocks=True, autoescape=False)
template = env.get_template('user_data.j2')
key = Path.home().joinpath('.ssh/bd2c_tp2.pub').read_text().strip()

for vm in inventory['vms']:
    profile = yaml.safe_load((root / 'profils' / f"{vm['profile']}.yaml").read_text())
    target = root / 'output' / vm['name']
    target.mkdir(parents=True, exist_ok=True)
    (target / 'user-data').write_text(template.render(**vm, **profile, ssh_public_key=key))
    (target / 'meta-data').write_text(
        f"instance-id: iid-bd2c-{vm['hostname']}\nlocal-hostname: {vm['hostname']}\n")
    subprocess.run(['genisoimage', '-quiet', '-output', 'seed.iso', '-volid', 'cidata',
                    '-joliet', '-rock', 'user-data', 'meta-data'], cwd=target, check=True)
    print(target)
