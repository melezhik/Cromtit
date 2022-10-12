# Cromtit cookbook

A collection of useful scenarios for different cases 

# Restart Apache server

This example would restart Apache server every Sunday 08:00 local server time.

Bash task:

```bash
mkdir -p tasks/apache/
cat << HERE > tasks/apache/restart.bash
sudo apachectl graceful
HERE
```

Tomtit scenario:

```bash
tom --edit apache-restart

#!raku

task-run "tasks/apache";
```

Cromtit jobfile

```yaml
projects:
  apache:
    path: git-repo-with-tomtit-scenarios
    action: restart
    crontab: "0 8 * * 0"
```
