# Web Frontend


### Running

Run the frontend in development mode with:

```bash
npm run dev
```

Alternatively you can run the project using docker-compose from the goTempM root folder:
```bash   
docker-compose up web  
```
*Note*: Docker-compose also starts the micro api gateway when you start the frontend. 
If you do not want that to happen, you can remove the dependency in the docker-compose file at the goTempM root folder 

Which ever way you decide to start the frontend, you will also need to run at least the user service to be able to login.

Open up [localhost:3000](http://localhost:3000) and start clicking around.

##### Sample landing Page

![goTempM landing page](../../diagramsforDocs/UI_goTempM_Landing_small.png)

##### Sample search Page

![goTempM landing page](../../diagramsforDocs/UI_Promo_detail.png)

##### Sample detail sage

![goTempM landing page](../../diagramsforDocs/UI_Promo_search.png)