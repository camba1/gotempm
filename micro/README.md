##Micro Usage

To run Micro in a docker container, we create a custom image to simplify usage. In particular, the customer container:

- Adds ```/``` to the PATH variable to be able to just call `micro` instead of `/micro`
- Sets the working directory to a new directory called `goTempM` which will be used to host our mounted volumes
