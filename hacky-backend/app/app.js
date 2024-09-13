import { app, update, uuid } from 'mu';

app.get('/fetch-decision-info/', async function (req, res) {
  // const uri = 'https://inventaris.onroerenderfgoed.be/aanduidingsobjecten/12581';
  const uri = req.query.uri; // Get the URI from the request parameter
  console.log(`Fetching and processing data from ${uri}`);
  const decisions = await fetchBesluitenAndParseTTL(uri);

  decisions.forEach(async decision => {
    const insert_query = generateSparqlInsertQuery(decision.ttl);
    update(insert_query);
  });

  res.send("ok");

});


async function fetchBesluitenAndParseTTL(uri) {
  try {
    // Step 1: Fetch the JSON data from the provided URI
    const response = await fetch(uri, {
      method: 'GET',
      headers: {
        'Accept': 'application/json'
      }
    });

    // Check if response is ok
    if (!response.ok) {
      throw new Error(`HTTP error! status: ${response.status}`);
    }

    // Step 2: Parse the JSON data
    const jsonData = await response.json();

    // Step 3: Extract the besluiten URIs
    const besluitenUris = jsonData.besluiten.map(besluit => besluit.uri);

    // Step 4: Fetch and parse each besluiten URI (assuming TTL format)
    const ttlDataPromises = besluitenUris.map(async (besluitUri) => {
      const ttlResponse = await fetch(besluitUri, {
        method: 'GET',
        headers: {
          'Accept': 'text/turtle'
        }
      });

      if (!ttlResponse.ok) {
        throw new Error(`Failed to fetch TTL data from ${besluitUri}, status: ${ttlResponse.status}`);
      }

      // Step 5: Parse the TTL data (For simplicity, we'll just return the raw text data)
      const ttlData = await ttlResponse.text();
      return {
        uri: besluitUri,
        ttl: ttlData
      };
    });

    // Await all TTL fetching promises
    const ttlResults = await Promise.all(ttlDataPromises);

    // Log or return the TTL data for further processing
    console.log(ttlResults);
    return ttlResults;

  } catch (error) {
    console.error('Error fetching or parsing data:', error);
  }
}

function generateSparqlInsertQuery(ttlData) {
  const prefixRegex = /@prefix\s+([a-zA-Z0-9]+):\s+<([^>]+)>/g;
  let prefixes = '';
  let content = ttlData;

  // Extract and convert @prefix to SPARQL PREFIX syntax
  let match;
  while ((match = prefixRegex.exec(ttlData)) !== null) {
    const prefix = match[1];
    const uri = match[2];
    prefixes += `PREFIX ${prefix}: <${uri}>\n`;
    // Remove the entire @prefix line including the trailing dot
    content = content.replace(new RegExp(`${match[0]}\\s*\\.`), '');
  }

  // Step 1: Process invalid subjects that are URIs but serialized as literals
  // Find literals that start with "http" or "https" and replace quotes with angle brackets
  content = content.replace(/"http([^"]+)"/g, '<http$1>');

  // Step 3: skolemize blank nodes. This is a mess.
  const skolemizedContent = skolemizeBlankNodes(content);
  content = skolemizedContent;
  // Looking for a lib,


  // Step 4: Construct the SPARQL query
  const sparqlQuery = `${prefixes}
INSERT DATA {
  GRAPH <http://mu.semte.ch/graphs/public> {
${content.trim()}
  }
}`;

  return sparqlQuery;
}

function skolemizeBlankNodes(ttlData) {
  const blankNodeRegex = /\[\s*([^\[\]]*?)\s*\]/g;
  let skolemizedContent = ttlData;

  let match;
  while ((match = blankNodeRegex.exec(ttlData)) !== null) {
    const blankNode = match[0];
    const skolemizedUri = `http://example.com/.well-known/erfgoed-besluit/${uuid()}`;
    skolemizedContent = skolemizedContent.replace(blankNode, `<${skolemizedUri}>`);
  }

  return skolemizedContent;
}


