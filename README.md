# PhD code Maximiliane Verfürden 
Code for Max Verfuerden's PhD linking dormant trials to the National Pupil Database

## Where to start
The 000-masterfile.do calls all other scripts (in stata lingo these are called do-files) in the right order and describes which datasets are created and used at which step.

## Project background 

_BACKGROUND:_

Randomised controlled trials (RCTs) that investigate the long-term effect of infant formula compositions suffer from substantial participant drop out over time. As a result, little is known about the long-term effects that different infant formula compositions have on children’s cognitive ability: an outcome that is of key interest to parents, policy makers and industry.

_METHODS:_ 

Using data from 2,208 participants I linked 7 different infant formula RCTs conducted in England (1993-2001) to the English administrative education database NPD. The primary end point was attainment at a compulsory maths exam at age 16, years. Secondary end points included educational attainment at age 11 and special educational needs status. Depending on the RCT, participants were healthy term infants, preterms or infants born small for gestational age and were given either iron-, LCPUFA-, nucleotide-, energy-, or sn-2 palmitate enriched formula or standard formula. 

## Software
This code was developed using Stata.

## Associated publications
Verfürden M, Harron K, Jerrim J, et al Infant formula composition and educational performance: a protocol to extend follow-up for a set of randomised controlled trials using linked administrative education recordsBMJ Open 2020;10:e035968. doi: 10.1136/bmjopen-2019-035968 https://bmjopen.bmj.com/content/10/7/e035968

## Purpose and data sharing
The purpose of this repository is to make my PhD data analysis transparent and reproducible. Unfortunately, the data cannot be shared because it is subject to a data sharing agreement which allows only identified and information-governance trained users to process it in a data safe haven which needs to have passed the latest IG toolkit standards. Because of this, I wrote the code in the UCL data safe haven (DSH), which does not have access to the internet. The code is subject to output control and has to be exported and uploaded manually.  
