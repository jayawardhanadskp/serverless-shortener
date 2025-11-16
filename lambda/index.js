const AWS = require('aws-sdk');
const dynamo = new AWS.DynamoDB.DocumentClient();
const TABLE_NAME = process.env.TABLE_NAME;
const BASE_URL = process.env.BASE_URL || 'https://yourdomain.com';

// Generate short code
function generateCode(length = 6) {
  const chars = 'abcdefghijklmnopqrstuvwxyzABCDEFGHIJKLMNOPQRSTUVWXYZ0123456789';
  let result = '';
  for (let i = 0; i < length; i++) {
    result += chars.charAt(Math.floor(Math.random() * chars.length));
  }
  return result;
}

// POST /shorten
exports.shortenHandler = async (event) => {
  const body = JSON.parse(event.body);
  const { url } = body;

  if (!url || !url.startsWith('http')) {
    return {
      statusCode: 400,
      body: JSON.stringify({ error: 'Valid URL required' })
    };
  }

  const shortCode = generateCode();
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
};

// GET /{code}
exports.redirectHandler = async (event) => {
  const { code } = event.pathParameters;

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

  // Increment click count
  await dynamo.update({
    TableName: TABLE_NAME,
    Key: { shortCode: code },
    UpdateExpression: 'SET clicks = clicks + :inc',
    ExpressionAttributeValues: { ':inc': 1 }
  }).promise();

  return {
    statusCode: 301,
    headers: { Location: result.Item.longUrl }
  };
};