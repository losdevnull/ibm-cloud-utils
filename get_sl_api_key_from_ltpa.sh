#!/usr/bin/env bash

# References:
# - https://console.stage1.bluemix.net/docs/developing/get-coding/token_service_examples.html
# - https://softlayer.github.io/rest/IBMidtoSLKey

# Env exports:
# - LTPA_COOKIE, BSS_ACCOUNT, IAM_CLIENT_ID, IAM_CLIENT_SECRET

creds=$(curl -s -u "${IAM_CLIENT_ID}:${IAM_CLIENT_SECRET}" -k -X POST --header "Content-Type: application/x-www-form-urlencoded" --header "Accept: application/json" --data-urlencode "grant_type=urn:ibm:params:oauth:grant-type:identity-cookie" --data-urlencode "response_type=cloud_iam,ims_portal" --data-urlencode "cookie=${LTPA_COOKIE}"  "https://iam.bluemix.net/identity/token?bss_account=${BSS_ACCOUNT}")

ims_token=$(echo $creds | jq -r '.ims_token')
ims_user_id=$(echo $creds | jq -r '.ims_user_id')
iam_access_token=$(echo $creds | jq -r '.access_token')

# Get api key over xmlrpc
curl -s -X POST -d "<?xml version=\"1.0\" encoding=\"UTF-8\"?>
<methodCall>
  <methodName>getObject</methodName>
  <params>
    <param>
      <value>
        <struct>
          <member>
            <name>headers</name>
            <value>
              <struct>
                <member>
                  <name>authenticate</name>
                  <value>
                    <struct>
                      <member>
                        <name>userId</name>
                        <value>
                          <int>$ims_user_id</int>
                        </value>
                      </member>
                      <member>
                        <name>complexType</name>
                        <value>
                          <string>PortalLoginToken</string>
                        </value>
                      </member>
                      <member>
                        <name>authToken</name>
                        <value>
                          <string>$ims_token</string>
                        </value>
                      </member>
                    </struct>
                  </value>
                </member>
                <member>
                  <name>SoftLayer_User_CustomerInitParameters</name>
                  <value>
                    <struct>
                      <member>
                        <name>id</name>
                        <value>
                          <int>$ims_user_id</int>
                        </value>
                      </member>
                    </struct>
                  </value>
                </member>
                <member>
                  <name>SoftLayer_ObjectMask</name>
                  <value>
                    <struct>
                      <member>
                        <name>mask</name>
                        <value>
                          <string>mask[username;apiAuthenticationKeys.authenticationKey]</string>
                        </value>
                      </member>
                    </struct>
                  </value>
                </member>
              </struct>
            </value>
          </member>
        </struct>
      </value>
    </param>
  </params>
</methodCall>" https://api.softlayer.com/xmlrpc/v3/SoftLayer_User_Customer > response.xml
SL_USERNAME=$(cat response.xml | xmllint --xpath '(//params/param/value/struct/member/value/string/text())[1]' -)
SL_API_KEY=$(cat response.xml | xmllint --xpath '(//params/param/value/struct/member/value/array/data/value/struct/member/value/string/text())[1]' -)

# echo "IAM_TOKEN: $iam_access_token"
echo "SL_USERNAME: $SL_USERNAME"
echo "SL_API_KEY: $SL_API_KEY"

rm -f response.xml
