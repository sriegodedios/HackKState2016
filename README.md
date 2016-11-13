#BetterDAI 

Better Doctors with artifical intellignce make better days for everyone

##Inspiration
We wanted to learn Django. We wanted to do data analysis.

The K-State SIGAI Group proposed a challenge. We want to use data science for the betterment of society. In order to combine these ideas, we concocted BetterDAI, an end to end data pipeline that betters the world.

Our goal was to predict which patients will be re-admitted to the hospital within 30 days of their discharge. This is a real problem for hospitals, who don't get paid for a re-admission if it happens within 30 days after the patient was discharged, and patients, who would like to live their life outside the walls of a hospital and be healthy.

##What it does
BetterDAI is a state of the art end to end pipeline that uses Python, Django, Sqlite, Twilio, DigitalOcean, Bootstrap, R, and Machine Learning.

Doctors insert data about all their patients into the form on the web application. This information is stored in a database.

The patient data stored in the database is then prepared and cleaned in order to pass it to our predictive model. The model predicts whether a patient has a high likelihood of being readmitted to the hospital within the next 30 days (that makes for a bad day). Our predictive model has an ensemble of analysis techniques used in order to ensure the highest precision (that makes for a better day).

Once the model has done its work, the doctor has access to top of the line analytics to help him make a decision in releasing a patient.

BetterDAI collects data, cleans it, processes it, and delivers it back with useful information. The full stack. The pipeline. The end to end solution for doctors everywhere. It is data science for good!

##How we built it

* We used R to create a model. We started with a basic decision tree based on the features and ended with a full out (insert our final    model description here).

* We used django to create a web application in python that allowed us to create an end to end system.

* We hosted our app on DigitalOcean using a domain from domain.com.

##Challenges we ran into/ Hacks we made

###DJANGO

Static files within Django. We spent countless hours trying to get a correct implementation, but ended up settling with a sub-par hack. (We hosted our css files on another DigitalOcean droplet and referenced them CDN-like through a URL)

The csrf_tokens. We tried to use them like good people, but they made everything harder, so we just left them out. Sorry security.

Getting the Django project to run on the DigitalOcean server. We ended up just pointing the domain to 127.0.0.1:8000.

None of us had worked with Django before, and now we have and probably won't again.

##Accomplishments that we're proud of

* Setting up domain with digital ocean droplet

* Running Django app on said domain

* Client/Server communication

* Create a model to analyze the data in R

* Integrating sqlite database

* Preparing csv file for analysis

* Providing an end-to-end solution for all the doctors of the world

#What we learned
R Django sqlite Machine Learning

##What's next for BetterDAI
After it is implemented by every hospital in the U.S. and many people's days have been made better, we will expand internationally and once we have expanded internationally everyone in the entire world's day will have been made better and there will be so much joy in the world that their will be world peace among all nations.
