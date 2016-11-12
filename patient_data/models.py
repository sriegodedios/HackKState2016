from django.db import models


# Create your models here.

class Info(models.Model):
    encounter_id = models.IntegerField(default=0)
    patient_nbr = models.IntegerField(default=0)
    race = models.IntegerField(default=0)
    gender = models.IntegerField(default=0)
    age = models.IntegerField(default=0)
    weight = models.IntegerField(default=0)
    admission_type_id = models.CharField(max_length=200)
    discharge_disposition_id = models.CharField(max_length=200)
    admission_source_id = models.CharField(max_length=200)
    time_in_hospital = models.CharField(max_length=200)
    payer_code = models.CharField(max_length=200)
    medical_specialty= models.CharField(max_length=200)
    num_lab_procedures = models.CharField(max_length=200)
    num_procedures = models.CharField(max_length=200)
    num_medications = models.CharField(max_length=200)
    number_outpatient = models.CharField(max_length=200)
    number_emergency= models.CharField(max_length=200)
    number_inpatient = models.CharField(max_length=200)
    diag_1 = models.CharField(max_length=200)
    diag_2 = models.CharField(max_length=200)
    diag_3 = models.CharField(max_length=200)
    num_diagnoses = models.CharField(max_length=200)
    max_glu_serum = models.CharField(max_length=200)
    A1Cresult = models.CharField(max_length=200)
    med_feature = models.CharField(max_length=200)
    change = models.CharField(max_length=200)
    diabetesMed = models.CharField(max_length=200)
    readmitted =models.CharField(max_length=200)




