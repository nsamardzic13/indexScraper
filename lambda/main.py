import os

from helper import Email


def lambda_handler(event, context):
    file = event['s3_path']
    category = event['category']
    
    target_email = os.environ.get('TARGET_EMAIL')
    email = Email(
        email_to=target_email,
        category=category
    )

    df = email.open_s3_file(file)
    # construct email
    html = """
        <h1>Price change</h1>
        <br>
        {{ df }}
        <br>
    """

    tables = {
        'df': df
    }

    email.send_email(
        html=html,
        tables=tables
    )