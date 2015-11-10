# Base Docker Image For Play Framework Docker Containers

All microservice Docker Containers based on Play Framework should use this as their base container.

This container:

- installs Java 8
- downloads all dependencies used by a minimal Play Framework project
- deletes everything else

The objective of this container is to allow incremental changes to the Play microservice that's based on this container to download only the new libraries they need, not the entire Play Framework after a new commit.
