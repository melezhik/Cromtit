# Cromtit

Crontab for your [Tomtit](https://github.com/melezhik/Tomtit) scenarios

# "What's in a name?"

Cromtit =  Cro(ntab) + Tomtit 

# Features

* Run Tomtit jobs as cron jobs

* Job dependencies 

* Asynchronous jobs queue with throttling 
to protect system overload

* See logs and reports using cro app

# Install

1. Install [Sparky](https://github.com/melezhik/sparky#installation)

2. Install cromtit

```bash
git clone https://github.com/melezhik/Cromtit.git
cd Cromtit
cro run
```

# Projects configuration

Create `~/cromtit.yaml`, it should contain a list of projects:

```yaml
# list of Tomtit projects
projects:
  - rakudo:
      path: ~/projects/rakudo
      crontab: "30 * * * *"
      action: install
      color: True # colorful output
      tomtit_options: --dump_task --env=dev
      config:
        foo: 1
        bar: 2
  - r3:
      path: ~/projects/r3tool
      crontab: "30 * * * *"
      action: install
      color: True # colorful output
```

## Project specific configuration

Every project might have a specific configuration:

```yaml
# run `tom install`
# every one hour
crontab: "30 * * * *"
action: install
color: True # colorful output
```

### Crontab

Should represents crontab entry (how often and when to run a project), should
follow [Sparky crontab format](https://github.com/melezhik/sparky#run-by-cron). 
Optional. If not set, implies manual run.

### Action

Should define name of tomtit scenario that will be run. Required.
 
### Color

Colorful output - require external dependency  (python module `ansi2html`). Optional.

### tomtit_options

Tomtit cli options. Optional

### config

Additional job configuration. Optional

# Web console

Cromtit exposes a web UI to track projects, cron jobs and reports:

http://127.0.0.1:6000



