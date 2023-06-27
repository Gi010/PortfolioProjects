-- Selecting data that we will use

select *
from Voting..voter_demographics$

select *
from Voting..voter_confidence$

-- Creating response returns for the keys using T-SQL

CREATE TABLE response_Yes_or_No_key -- For Yes or No questions
(Response_key int, Response varchar(255))

INSERT INTO response_Yes_or_No_key
VALUES (1, 'Yes'),
	   (0, 'No')

select *
from response_Yes_or_No_key  -- Check

CREATE TABLE response_scaled_key -- For scaled questions (1 to 4)
(Response_key int, Response varchar(255))

INSERT INTO response_scaled_key
VALUES (1, 'High'),
	   (2, 'Medium high'),
	   (3, 'Medium low'),
	   (4, 'Low')

select *
from response_scaled_key  -- Check


-- Cleaning the response keys from negative signs to leave absolute values

UPDATE Voting..voter_confidence$
SET Voting_importance = ABS(Voting_importance),
	Following_politics = ABS(Following_politics),
	Believing_in_god = ABS(Believing_in_god),
	Trust_in_presidency = ABS(Trust_in_presidency),
	Trust_in_court = ABS(Trust_in_court),
	Trust_in_elections = ABS(Trust_in_elections),
	Trust_in_intelligence = ABS(Trust_in_intelligence),
	Trust_in_news_media = ABS(Trust_in_news_media),
	Trust_in_police = ABS(Trust_in_police),
	long_term_disability = ABS(long_term_disability),
	Chronic_illness = ABS(Chronic_illness),
	Unemployed_for_1_year = ABS(Unemployed_for_1_year),
	Lost_job = ABS(Lost_job),
	Evicted_from_home = ABS(Evicted_from_home),
	Worried_about_basic_expenses = ABS(Worried_about_basic_expenses),
	Voting_difficulty = ABS(Voting_difficulty),
	Trust_in_voting_machines = ABS(Trust_in_voting_machines),
	Trust_in_paper_ballots = ABS(Trust_in_paper_ballots),
	Trust_in_mail_ballots = ABS(Trust_in_mail_ballots),
	Registered_to_vote = ABS(Registered_to_vote)


/* Demographics of non-voters

   Creating age categories of non-voters */

select dem.ID,
	   Age,
	   Gender,
	   Education,
	   Income_category,
	   case when age <=30 then 'young'
			when age <=60 then 'middle age'
			else 'old' 
			end 'age_category'
from Voting..voter_demographics$ dem
left join Voting..voter_confidence$ con on con.ID = dem.ID
where con.Voter_category = 'rarely/never'

-- Breaking down the number of total non-voters by age categories using CTE

with NonVotersByAgeCat (ID, Age, Gender, Education, Income_category, age_category) 
as (
select dem.ID,
	   Age,
	   Gender,
	   Education,
	   Income_category,
	   case when age <=30 then 'young'
			when age <=60 then 'middle age'
			else 'old' 
			end 'age_category'
from Voting..voter_demographics$ dem
left join Voting..voter_confidence$ con on con.ID = dem.ID
where con.Voter_category = 'rarely/never'
)
select age_category,
	   (select COUNT(*) from NonVotersByAgeCat where age_category = nc.age_category) as NumberOfPeople
from (select distinct age_category from NonVotersByAgeCat) nc
order by NumberOfPeople desc

-- Showing percentage breakdown of non-voters by age categories

with NonVotersByAgeCat (ID, Age, Gender, Education, Income_category, age_category) 
as (
    select dem.ID,
           Age,
           Gender,
           Education,
           Income_category,
           case when age <= 30 then 'young'
                when age <= 60 then 'middle age'
                else 'old' end 'age_category'
    from Voting..voter_demographics$ dem
    left join Voting..voter_confidence$ con ON con.ID = dem.ID
    where con.Voter_category = 'rarely/never'
),
AgeCategoryCounts as (
    select age_category,
           COUNT(ID) as NumberOfPeople,
           COUNT(ID) * 1.0 / SUM(COUNT(ID)) over () as Percentage
    from NonVotersByAgeCat
    group by age_category
)
select age_category,
       NumberOfPeople,
       CAST(ROUND(Percentage * 100, 2) as numeric(5,2)) as Percentage
from AgeCategoryCounts
order by Percentage desc

-- Educational background breakdown of non-voters in numbers and percentage of total

select Education,
	   COUNT(dem.ID) as Non_Voters_Count,
	   CONVERT(decimal(5,2),COUNT(dem.ID) *1.0 / SUM(COUNT(dem.ID)) over () * 100) as Percentage
from Voting..voter_demographics$ dem
left join Voting..voter_confidence$ con on con.ID = dem.ID
where con.Voter_category = 'rarely/never'
group by Education
order by Percentage desc

-- Number and percentage of people who think voting is important

select yn.response,
	   SUM(COUNT(Voting_importance)) over(partition by Voting_importance) as ShareCount,
	   CONVERT(decimal(5,2),SUM(COUNT(Voting_importance)) over(partition by Voting_importance) * 100.0 / SUM(COUNT(Voting_importance)) over ()) as Percentage
from Voting..voter_confidence$ con
left join Voting..response_Yes_or_No_key yn on yn.Response_key = con.Voting_importance
group by Voting_importance, yn.response

-- Percentage of people following politics

select yn.response,
	   CONVERT(decimal(5,2),SUM(COUNT(Following_politics)) over(partition by Following_politics) * 100.0 / SUM(COUNT(Following_politics)) over ()) as Percentage
from Voting..voter_confidence$ con
left join Voting..response_Yes_or_No_key yn on yn.Response_key = con.Following_politics
group by Following_politics, yn.response

-- Trust in presidency among non-voters

select sc.Response,
	   CONVERT(decimal(5,2),SUM(COUNT(Trust_in_presidency)) over (partition by Trust_in_presidency) * 100.0 / SUM(COUNT(Trust_in_presidency)) over ()) as Percentage
from Voting..voter_confidence$ con
left join Voting..response_scaled_key sc on sc.Response_key = con.Trust_in_presidency
where con.Voter_category = 'rarely/never'
group by Trust_in_presidency, sc.Response

-- Educational background share for each level of trust in elections

select dem.Education,
	   sc.Response as Trust_in_elections,
	   CONVERT(decimal(5,2),SUM(COUNT(con.Trust_in_elections)) over (partition by con.Trust_in_elections, Education) * 100.0 / 
	   SUM(COUNT(con.Trust_in_elections)) over (partition by con.Trust_in_elections)) as Percentage
from Voting..voter_demographics$ dem
inner join Voting..voter_confidence$ con on con.ID = dem.ID
left join Voting..response_scaled_key sc on sc.Response_key = con.Trust_in_elections
group by  con.Trust_in_elections,  sc.Response, dem.Education

-- Age category breakdown for each level of trust in elections 
-- Using CTE

with AgeCategory as (
select ID,
	   case when age <=30 then 'young'
			when age <=60 then 'middle age'
			else 'old' end 'age_category'
from Voting..voter_demographics$
)
select ac.age_category,
		sc.Response as Trust_in_elections,
		CONVERT(decimal(5,2),SUM(COUNT(con.Trust_in_elections)) over (partition by con.Trust_in_elections, ac.age_category) * 100.0 / 
		SUM(COUNT(con.Trust_in_elections)) over (partition by con.Trust_in_elections)) as percentage
from Voting..voter_confidence$ con
inner join AgeCategory ac on ac.ID = con.ID
left join Voting..response_scaled_key sc on sc.Response_key = con.Trust_in_elections
group by  con.Trust_in_elections,  sc.Response, ac.age_category

-- Age category breakdown for each level of trust in elections 
-- Using subquery

select subquery.age_category,
	   sc.Response as Trust_in_elections,
	   CONVERT(decimal(5,2),COUNT(*) * 100.0 / SUM(COUNT(*)) over (partition by sc.Response)) as Percentage
from ( select ID,
			  case when age <= 30 then 'young'
              when age <= 60 then 'middle age'
              else 'old'
              end as age_category
       from Voting..voter_demographics$
    ) as subquery
inner join Voting..voter_confidence$ con on con.ID = subquery.ID
left join Voting..response_scaled_key sc on sc.Response_key = con.Trust_in_elections
group by
age_category, sc.Response
order by 2