# Cromtit

Crontab (and more) for your [Tomtit](https://github.com/melezhik/Tomtit) scenarios

# "What's in a name?"

Cromtit =  Cro(ntab) + Tomtit 

# Features

* Run Tomtit jobs as cron jobs

* Job dependencies 

* Asynchronous jobs queue with throttling 
to protect a system from overload

* See job logs and reports using cro app

# Install

Cromtit uses Sparky as job runner engine, so please install
and configure Sparky first:

1. Install [Sparky](https://github.com/melezhik/sparky#installation)

Now, all you need is to starts Cromtit web api:

2. Install Cromtit

```bash
git clone https://github.com/melezhik/Cromtit.git
cd Cromtit
zef install . --/test
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
      tomtit_options: --dump_task --env=dev
      vars: 
        foo: 1
        bar: 2
  - r3:
      path: ~/projects/r3tool
      crontab: "30 * * * *"
      action: install
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

Should define name of tomtit scenario that will be run. Required
 
### tomtit_options

Tomtit cli options. Optional

### vars

Additional environment variables get passed to a job. Optional

## Job Dependencies

Projects might have dependencies, so that some jobs might be run before or after
a project's job:


```yaml
projects:

  - database:
      path: ~/projects/database

  - web-test:
      path: ~/projects/web-test
      action: run
      before: database
        action: spinoff
        vars:
          db_name: test
          db_user: test
          db_password: pass
      after: database
        action: remove 
        vars:
          db_name: test
```

So `before` and `after` objects accepts following parameters:

### name

Project name. Required

### action

See project action job. Optional

### vars

See project job vars. Optional

# Web console

Cromtit exposes a web UI to track projects, cron jobs and reports:

http://127.0.0.1:6000
