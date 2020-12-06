End2End run for the generic streaming library

I wanted to complement a bit the generic streaming library available in https://github.com/jsoft88/structured-streaming-lib, which included a sample use case, which had as input two kafka topics, namely, pageviews and users, and had to produce output to another kafka topic (top_pages), these are the requirements:

* Join the messages in these two topics on the user id field
* A 1 minute hopping window with 10 second advances to compute the 10 most viewed pages by viewtime for every value of gender
* Once per minute produces a dataframe that contains the gender, page id, sum of view time in the latest window and distinct count of user ids in the latest window

More details about the generic library and this full run, can be found in the articles @ linkedIn link1 and link2, respectively.

# Requirements
* Docker v19+
* Git
* At least 10gb memory free and 10gb disk space

# Execution
`bash run.sh <ip_of_host>`

This will trigger the full run with defaults. You can inspect the run.sh file to see what the default values are, but here is a list:

* Scala version -> 2.11
* Lib version -> 0.1
* Jar name -> streaming-lib-assembly
* Jar destination in working directory (where the project is cloned) -> target/scala-2.11/${Jar name}.jar
* Confluent platform version 6.0.0-post

To override these parameters, invoke the function like this:
`bash run.sh <ip_of_host> <scala_version> <lib_version> <jar_name> <jar_destination> <confluent_platform_version>

Also it is worth mention the environment file in `env/airflow_env.json`, which is the file used to setup the environment variables in Airflow. Check if all the values there make sense for you, since if you changed any the docker/docker-compose files, things might also be broken there.

To clean up the whole setup, run `bash stop_all.sh`.