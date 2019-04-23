import pika
import os


def viewQueueMessages(connection, channel, queue, batch_size):
    """
    Method to only view messages in a queue 100 messages at a time
    """
    print("Only viewing messages in the queue: ", queue)
    for method_frame, properties, body in channel.consume(queue):
        channel.basic_nack(method_frame.delivery_tag, requeue=True)
        print(method_frame, properties, body)
        if method_frame.delivery_tag == batch_size:
            break
    channel.close()
    connection.close()


def drainQueue(connection, channel, queue, batch_size):
    """
    Method to drain a queue 100 messages at a time
    """
    print("Consuming messages in the queue: ", queue)
    for method_frame, properties, body in channel.consume(queue):
        print(method_frame, properties, body)
        channel.basic_ack(method_frame.delivery_tag)
        if method_frame.delivery_tag == batch_size:
            break
    channel.close()
    connection.close()


def main():

    # if set to 1, drain the queue; else defaults to 0 to only read messages
    DRAIN_QUEUE = int(os.environ.get('DRAIN_QUEUE', 0))
    # set the queue to work on; defaults to celery
    QUEUE_NAME = os.environ.get('QUEUE_NAME', 'celery')
    # assuming we are port forwarding rabbit-node to localhost
    HOST = os.environ.get('HOST', 'localhost')
    # defaults to default rabbit port
    PORT = int(os.environ.get('PORT', 5672))
    # deafults to '/' if not set.
    # allowed vhost values: [qa1, qa2, qa3, qa4, perf, demo, mobile, sandbox, int, test1, test2]
    VHOST = os.environ.get('VHOST', '/')
    # defaults to 'guest'
    RABBIT_USER = os.environ.get('RABBIT_USER', 'guest')
    # defaults to 'guest'
    RABBIT_PWD = os.environ.get('RABBIT_PWD', 'guest')
    # Number of messages to read at a time, defaults to 100
    BATCH_SIZE = int(os.environ.get('BATCH_SIZE', 100))

    # setup credentials and parameters; open channel
    credentials = pika.PlainCredentials(RABBIT_USER, RABBIT_PWD)
    parameters = pika.ConnectionParameters(HOST, PORT, VHOST, credentials)
    connection = pika.BlockingConnection(parameters=parameters)
    channel = connection.channel()

    if DRAIN_QUEUE == 1:
        drainQueue(connection, channel, QUEUE_NAME, BATCH_SIZE)
    else:
        viewQueueMessages(connection, channel, QUEUE_NAME, BATCH_SIZE)


if __name__ == '__main__':
    main()
