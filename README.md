# Elmer Dockerfile

This dockerfile will build elmerice. By default, it will build the latest version of elmerice, but it is possible to change that by using docker build arguments:

```
docker build --build-arg gitCommit=<commit> <rest of normal arguments>
```

This will be automatically built on DockerHub
