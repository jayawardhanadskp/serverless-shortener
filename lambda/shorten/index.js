const AWS = require('aws-sdk');
const dynamo = new AWS.DynamoDB.DocumentClient();
const TABLE_NAME = process.env.TABLE_NAME;
const BASE_URL = process.env.BASE_URL || 'https://yourdomain.com';

function generateCode(length = 6) {
  const chars = 'abcdefghijklmnopqrstuvwxyzABCDEFGHIJKLMNOPQRSTUVWXYZ0123456789';
  let result = '';
  for (let i = 0; i < length; i++) {
    result += chars.charAt(Math.floor(Math.random() * chars.length));
  }
  return result;
}

exports.shortenHandler = async (event) => {
  try {
    const body = JSON.parse(event.body || '{}');
    const { url } = body;

    if (!url || !url.startsWith('http')) {
      return {
        statusCode: 400,
        body: JSON.stringify({ error: 'Valid URL required' })
      };
    }

    // try generating unique code (simple retry loop)
    let shortCode;
    for (let i = 0; i < 5; i++) {
      shortCode = generateCode(6);
      const exists = await dynamo.get({ TableName: TABLE_NAME, Key: { shortCode } }).promise();
      if (!exists.Item) break;
      shortCode = null;
    }
    if (!shortCode) {
      return { statusCode: 500, body: JSON.stringify({ error: 'Failed to generate unique code' }) };
    }

    const params = {
      TableName: TABLE_NAME,
      Item: {
        shortCode,
        longUrl: url,
        clicks: 0,
        createdAt: new Date().toISOString()
      }
    };

    await dynamo.put(params).promise();

    return {
      statusCode: 200,
      headers: { 'Content-Type': 'application/json' },
      body: JSON.stringify({
        shortUrl: `${BASE_URL}/${shortCode}`,
        longUrl: url
      })
    };
  } catch (err) {
    console.error(err);
    return { statusCode: 500, body: JSON.stringify({ error: 'Internal error' }) };
  }
};
