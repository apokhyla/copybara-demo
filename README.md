<h2>Prerequisites</h2>

Copybata setup steps and documentation: https://github.com/google/copybara

<h2>How to run</h2>

Sync (source -> destination):

```
java -jar copybara_deploy.jar copybara-demo/local/copy.bara.sky sync --ignore-noop
```

Backport (destination -> source):

```
java -jar copybara_deploy.jar copybara-demo/local/copy.bara.sky backport --ignore-noop
```

Note, that during the first time Copybara will require the ```--init-history``` flag passed.