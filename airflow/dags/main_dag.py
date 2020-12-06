from airflow import DAG
from airflow.operators.python_operator import PythonOperator
from airflow.operators.bash_operator import BashOperator
from datagen.kafka_datagen import TriggerKafkaDataGen
from airflow.models import Variable
from datetime import datetime

default_args = {}

kafka_datagen = TriggerKafkaDataGen()

topic_pageviews_config = Variable.get("TOPIC_PAGEVIEWS_CONFIG")
topic_users_config = Variable.get("TOPIC_USERS_CONFIG")
post_url = Variable.get("POST_URL")
spark_docker_image = Variable.get("SPARK_DOCKER_IMAGE")
stream_lib_jar_path_in_container = Variable.get("STREAM_LIB_JAR_PATH_IN_CONTAINER")
stream_lib_args = Variable.get("STREAM_LIB_ARGS")
container_comms = Variable.get("CONTAINER_COMMS")

dag = DAG(
    "e2e-dag",
    default_args=default_args,
    description="A fully running example of the top 10 pages by gender scenario",
    start_date=datetime(2020, 1, 1, 0, 0, 0),
    schedule_interval=None
)

stage_start_pageviews_producer = PythonOperator(
    task_id="start_pageviews_producer",
    python_callable=kafka_datagen.trigger_execution,
    op_args=[post_url, f"resources/{topic_pageviews_config}"],
    dag=dag
)

stage_start_users_producer = PythonOperator(
    task_id="start_users_producer",
    python_callable=kafka_datagen.trigger_execution,
    op_args=[post_url, f"resources/{topic_users_config}"],
    dag=dag
)

stage_start_spark_streaming_library = BashOperator(
    task_id="start_spark_streaming_library",
    bash_command=f"echo \"--conf spark.jars.ivy=/tmp/.ivy --class com.org.challenge.stream.AppLibrary {stream_lib_jar_path_in_container} {stream_lib_args}\" > {container_comms}",
    dag=dag
)

stage_start_pageviews_producer >> stage_start_users_producer >> stage_start_spark_streaming_library