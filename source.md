
const ninNum = args[0];
const firstName = args[1];
const lastName = args[2];
const voterMatricNo = args[3];
const clientId=secrets.VERIFYME_CLIENT_ID;
const authKey=secrets.VERIFYME_TESTKEY;
if(!authKey||!clientId){
  console.error("Secret key or clientId not found!");
  throw Error("Secret key or clientId not found!");
}

if(!ninNum||!firstName||!lastName){

  console.error("One or more of nin, firstName and lastname is null",ninNum,firstName,lastName);
  throw Error("Request failed: One or more of nin, firstName and lastname is null");
}

// Execute the API request (Promise)
const authApiResponse=await Functions.makeHttpRequest({
  method:"POST",
  url:"https://api.qoreid.com/token",
  data = {
    "secret": authKey,
    "clientId": clientId
},
  headers = {
    "accept": "text/plain",
    "content-type": "application/json"
}});


if (authApiResponse.error) {
  console.error(authApiResponse.error);
  throw Error("Request failed");
}

// Execute the API request (Promise)
const apiResponse = await Functions.makeHttpRequest({
  method:"POST",
  url: `https://api.qoreid.com/v1/ng/identities/nin/${ninNum}`,
  headers: {
    "accept": "application/json",
    "content-type": "application/json",
    "authorization": `Bearer ${authApiResponse.accessToken}`
    },
  data:{
    "firstname": firstName,
    "lastname": lastName
    }
});

if (apiResponse.error) {
  console.error(apiResponse.error);
  throw Error("Request failed");
}

const { data } = apiResponse;

console.log('API response data:', JSON.stringify(data, null, 2));

return Functions.encodeString(voterMatricNo);

