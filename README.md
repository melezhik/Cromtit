# Cromtit

Run [Tomtit](https://github.com/melezhik/Tomtit) scenarios as cron jobs and more.

![web ui](https://raw.githubusercontent.com/melezhik/Cromtit/main/samples/web-ui.jpeg)

# Build status

[![SparkyCI](http://sparrowhub.io:2222/project/gh-melezhik-Cromtit/badge)](http://sparrowhub.io:2222)

# "What's in a name?"

Cromtit =  Crontab + Tomtit 

# Features

* Run Tomtit jobs as cron jobs

* Job dependencies 

* Asynchronous jobs queue 

* Distributed jobs

* Throttling to protect a system from overload (TBD)

* View job logs and reports via cro app web interface

# Install

Cromtit uses Sparky as job runner engine, so please install
and configure Sparky first:

1. Install [Sparky](https://github.com/melezhik/sparky#installation)

2. Install Cromtit

```bash
zef install Cromtit
```

# Configure

Create `~/cromtit.yaml` file, see `Projects configuration` section. 

Once a configuration file is created, apply changes:

```bash
cromt
```

# ~/cromtit.yaml specification

 `~/cromtit.yaml` should contain a list of Tomtit projects:

```yaml
# list of Tomtit projects
projects:
  rakudo:
    path: ~/projects/rakudo
  r3:
    path: ~/projects/r3tool
    crontab: "30 * * * *"
    action: pull html-report
    options: --no_index_update --dump_task
    before:
      -
        name: rakudo
        action: pull install 
```

## Project specific configuration

Every project item  has a specific configuration:

```yaml
  app:
    # run `tom install` 
    # every one hour
    crontab: "30 * * * *"
    action: install
    # with tomtit options:
    options: --no_index_update
    # setting env variables:
    vars:
      foo: 1
      bar: 2
```

### Key

Key should define a unique project name.

### action

Should define name of tomtit scenario that will be run. Optional.

```yaml
action: install
```
Multiple actions could be set as a space separated string:

```yaml
# will trigger `tom pull` && `tom build` && `tom install`
action: pull build install
```

### path

Tomtit project path. Optional. 

Either:

* file path

Sets local directory path with Tomtit project:

```yaml
path: ~/projects/r3
```

Or:

* git repo

Sets git repository with Tomtit project

```
path: git@github.com:melezhik/r3tool.git
```

### crontab

Should represents crontab entry (how often and when to run a project), should
follow [Sparky crontab format](https://github.com/melezhik/sparky#run-by-cron).
Optional. If not set, implies manual run.


```yaml
# run every 10 minutes
crontab: "*/10 * * * *"
```

### options

Tomtit cli options. Optional

```yaml
options: --dump_task --verbose
```

### vars

Additional environment variables get passed to a job. Optional

```yaml
vars:
  # don't pass creds
  # as clear text
  user: admin
  password: SecRet123

```

### hosts

By default jobs get run on localhost. 

To run jobs on specific hosts in parallel, use `hosts` list:

```yaml
projects:
  system-update:
    path: ~/project/system-update
    options: update
  # runs `tom update` on every host
  # in parallel
  hosts:
    - 
      url: https://192.168.0.1 
    - 
      url: https://192.168.0.2 
    - 
      url: https://192.168.0.3
```

Hosts list should contain a list of Sparky API URLs 
and hosts need to be a part of the same [Sparky cluster](https://github.com/melezhik/sparky#cluster-jobs).

Optionally every host could override vars:

```yaml
  hosts:
    - 
      url: https://192.168.0.1
      vars:
        WORKER: 1 
    - 
      url: https://192.168.0.2 
      vars:
        WORKER: 2 
    - 
      url: https://192.168.0.3
      vars:
        WORKER: 3
```

## Job Dependencies

Projects might have dependencies, so that some jobs might be run before or after
a project's job:


```yaml
projects:

  database:
    path: ~/projects/database

  app:
    path: ~/projects/app
    action: test
    before: 
      -
        name: database
        action: create
        vars:
          db_name: test
          db_user: test
          db_password: pass
    after:
      - 
        name: database
        action: remove 
        vars:
          db_name: test
```

So, `before` and `after` are list of objects that accept following parameters:

### name

Project name. Required

### action

Override project job action. Optional. See project action specification.

### vars

Override project job vars. Optional. See project vars specification.

### hosts

Override project job hosts. Optional. See project hosts specification.

## Nested Dependencies

Nested dependencies are allowed, so a dependency might have another dependency, so on.

Just be cautious about cycles. This should be directed acycling graph of dependencies.

# Artifacts

Jobs can share artifacts with each other:

```yaml
projects:
  fastspec-build:
    path: git@github.com:melezhik/fastspec.git
    action: build-rakudo
    artifacts:
      out:
        -
          file: rakudo.tar.gz:
          path: .build/rakudo.tar.gz
  fastspec-test:
    path: git@github.com:melezhik/fastspec.git
    action: spectest
    after:
      -
        name: fastspec-build
    artifacts:
      in:
        - rakudo.tar.gz  
    hosts:
      -
        url: https://sparrowhub.io:4000
        vars:
          WORKER: 1
      -
        url: https://192.168.0.3:4001
        vars:
          WORKER: 2
      -
        url: http://127.0.0.1:4000
        vars:
          WORKER: 3
```

In this example dependency job `fastspec-build` copies file `.build/rakudo.tar.gz` into _internal storage_
so that dependent job `fastspec-test` would access it. The file will be located within tomtit scenario at
`.artifacts/rakudo.tar.gz` path.

# cromt cli

`cromt` is a Cromtit cli.

Options:

## --conf

Path to cromtit configuration file to apply. Optional. Default value is `~/cromtit.yaml`

# Configuration file example

You can find a configuration file example at `examples/` directory

# Web console

Sparky exposes a web UI to track projects, cron jobs and reports:

http://127.0.0.1:4000

# Thanks to

God and Christ as "For the LORD gives wisdom; from his mouth come knowledge and understanding."
