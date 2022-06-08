# Sample containerized Python application to accomplish the following: 

## procure infrastructure in GCP using terraform
## deploy code to staging and master using Github actions 

1. running locally
``` docker-compose up ```

2. push code to master will trigger staging deployment

3. Adding a tag and pushing it will trigger a production deployment 
``` eg. git tag v0.0.1  ```
``` git push origin v0.0.1 ```


## Sample app details:

1. staging: http://34.132.223.213:5001/
2. prod: http://35.194.28.63:5001/
3. Application present in the following project: l-gs-gsrd-general


## Technologies
1. Docker
2. GCP vm instances
3. Terraform
4. Github actions
5. GCP secret management