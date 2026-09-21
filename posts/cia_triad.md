# CIA Triad

Anyone who have wondered the path of Cybersecurity have came acrross this in the very beginning of their journey, so as we begin our adventure I think we shall to.

So What's CIA Triad what does it stand for what does it mean?

* **C** : Confidentiality
* **I** : Intefrity
* **A** : Availability

![Architectural diagram explaining the CIA Triad with Authentication and Non-Repudiation](assets/images/cia_triad_diagram.png)

**Confidentiality** : We need to make sure what's supposed to be private is always yes that includes you `API_KEYS` which you forgot to save in `.env`, and also not make a `.gitignore`, but more than that keeping trade secrets safe, user and employee info which they entrust in you, no one wants their Phone Number, Social Security Number, Address, etc. to be publicly available in the hands of an OSINT.

**Integrity** : The Data should be free of tampering, we wouldnt want if someone can get inside your database of let's say hospital change vital fields like Blood group, Organ Donor, Past illnesses, Allergies, etc. these can be fatal and endangering a patients life.

**Availability** : Your Services should always be serving, if you call for Ambulance and they deny you a service we can assume where it might lead to, which shouldn't be happening as if you fail to serve the end user suffers. attack in this category is : `DoS` i.e. Denial-of-Service attack commonly done on websites by sending trmemndous requests at exponential pace and then overwhelming the Server's compute and thus making it non-functional.

---

so this was CIA Triad, it's now accompanied by two more things:
**1. Authentication** & **2. Non Repudiation**

**Authentication** : Last thing we wish to do is talk to To Riddle via his diary only to find out he is Lord Voldemort himself, so knowing who we are dealing with, serving, etc is of paramount importance. and for each new Authentication method we tend to also develop a method to crack it as we know Brute-Force Attacks on Pin & Passwords, Fingerprint copying, session highjacking via cookies, etc.

**Non Repudiation** : You wouldn't wish if some sends a proposal, threat and then categorically deny it. so senders can't deny that this wasn't send by them / their device.

This was my introductory summary of CIA Traid + Authentication + Non-Repudiation.

May The Force Be With You !