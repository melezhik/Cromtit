# Cromtit

Crontab for your [Tomtit](https://github.com/melezhik/Tomtit) scenarios


# Install

1. Install [Sparky](https://github.com/melezhik/sparky#installation)

2. Install cromtit

```bash
git clone https://github.com/melezhik/Cromtit.git
cd Cromtit
cro run
```

# Configuration

Create `~/cromtit.yaml`

```yaml
# list of Tomtit projects
projects:
  - rakudo:
    - path: ~/projects/rakudo
  - r3:
    - path: ~/projects/r3tool
```

# Projects configuration

In every project create a `.cromtit.yaml` file inside root directory:

```yaml
# run 
crontab: "30,50,55 * * * *"
action: install
```

## Crontab

Should represents crontab entry (how often and when to run a project), should
follow [Sparky crontab format](https://github.com/melezhik/sparky#run-by-cron)

## Action

Should define name of tomtit scenario that will be run
 

# Web console

Cromtit exposes a web UI to track projects crontab runs and reports:

http://127.0.0.1:6000



