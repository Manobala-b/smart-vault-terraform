import boto3
import datetime
import os
import json

ec2 = boto3.client('ec2')
sns = boto3.client('sns')
s3 = boto3.client('s3')

SNS_TOPIC_ARN = os.environ['SNS_TOPIC_ARN']
S3_BUCKET = os.environ['S3_BUCKET']
RETENTION_DAYS = int(os.environ['RETENTION_DAYS'])

def lambda_handler(event, context):
    try:
        backup_time = datetime.datetime.utcnow()
        expired_time = backup_time - datetime.timedelta(days=RETENTION_DAYS)
        snapshot_logs = []

        # Find volumes tagged with Backup=true
        instances = ec2.describe_instances(
            Filters=[{'Name': 'tag:Backup', 'Values': ['true']}]
        )

        for reservation in instances['Reservations']:
            for instance in reservation['Instances']:
                for mapping in instance['BlockDeviceMappings']:
                    volume_id = mapping['Ebs']['VolumeId']
                    instance_id = instance['InstanceId']

                    # Create Snapshot
                    snapshot = ec2.create_snapshot(
                        VolumeId=volume_id,
                        Description=f"Auto backup from {instance_id} on {backup_time}"
                    )

                    ec2.create_tags(Resources=[snapshot['SnapshotId']],
                                    Tags=[{'Key': 'Name', 'Value': f"{instance_id}-backup"}])

                    snapshot_logs.append({
                        'instance_id': instance_id,
                        'volume_id': volume_id,
                        'snapshot_id': snapshot['SnapshotId'],
                        'created_at': backup_time.isoformat()
                    })

        # Delete old snapshots
        snapshots = ec2.describe_snapshots(OwnerIds=['self'])['Snapshots']
        for snap in snapshots:
            if 'Description' in snap and 'Auto backup' in snap['Description']:
                if snap['StartTime'].replace(tzinfo=None) < expired_time:
                    ec2.delete_snapshot(SnapshotId=snap['SnapshotId'])

        # Upload logs to S3
        log_key = f"snapshot-logs/backup-{backup_time.strftime('%Y-%m-%d-%H-%M')}.json"
        s3.put_object(
            Bucket=S3_BUCKET,
            Key=log_key,
            Body=json.dumps(snapshot_logs),
            ContentType='application/json'
        )

        # Send success alert
        sns.publish(
            TopicArn=SNS_TOPIC_ARN,
            Subject="✅ Smart Backup Success",
            Message=f"Snapshot created & old ones deleted.\nLog: s3://{S3_BUCKET}/{log_key}"
        )

    except Exception as e:
        # Send failure alert
        sns.publish(
            TopicArn=SNS_TOPIC_ARN,
            Subject="❌ Smart Backup Failed",
            Message=str(e)
        )
        raise
