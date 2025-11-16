const AWS = require('aws-sdk');
const dynamo = new AWS.DynamoDB.DocumentClient();
const TABLE_NAME = process.env.TABLE_NAME;

exports.redirectHandler = async (event) => {
  try {
    const code = (event.pathParameters && event.pathParameters.code) || null;
    if (!code) {
      return { statusCode: 400, body: JSON.stringify({ error: 'Code required' }) };
    }

    const params = {
      TableName: TABLE_NAME,
      Key: { shortCode: code }
    };

    const result = await dynamo.get(params).promise();

    if (!result.Item) {
      return {
        statusCode: 404,
        body: JSON.stringify({ error: 'Not found' })
      };
    }

    // Increment click count (best-effort)
    try {
      await dynamo.update({
        TableName: TABLE_NAME,
        Key: { shortCode: code },
        UpdateExpression: 'SET clicks = if_not_exists(clicks, :zero) + :inc',
        ExpressionAttributeValues: { ':inc': 1, ':zero': 0 }
      }).promise();
    } catch (e) {
      console.warn('Failed to increment clicks', e);
    }

    return {
      statusCode: 301,
      headers: {
        Location: result.Item.longUrl
      },
      body: null
    };
  } catch (err) {
    console.error(err);
    return { statusCode: 500, body: JSON.stringify({ error: 'Internal error' }) };
  }
};
