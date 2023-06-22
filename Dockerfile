FROM debian:bullseye

# Update package lists and install dependencies
RUN apt-get update && \
    apt-get install -y iproute2 bridge-utils iputils-ping

# Copy the netns-setup.sh script to the container
COPY netns-setup.sh /
COPY netns-teardown.sh /
COPY netns-test.sh /

# Set the working directory 
WORKDIR /root

# Make the script executable
RUN chmod +x /netns-setup.sh
RUN chmod +x /netns-teardown.sh
RUN chmod +x /netns-test.sh

# Set the entrypoint for the container
ENTRYPOINT ["/bin/bash", "-l"]

