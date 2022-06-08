terraform {

    backend "gcs" {

        bucket = "l-gs-gsrd-general-terraform" 
        prefix = "/hello-devops" 



    }




}