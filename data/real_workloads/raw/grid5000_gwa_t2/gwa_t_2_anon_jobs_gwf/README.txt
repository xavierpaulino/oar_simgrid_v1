Grid description: 

Grid'5000 is an experimental grid platform consisting of 9 sites
geographically distributed in France.  Each site comprises one or
several clusters, for a total of 15 clusters inside Grid'5000.  We
have acquired traces recorded by all batch schedulers handling
Grid'5000 clusters (OAR), from the beginning of the Grid'5000 project
up to the 10th of November 2006. The OAR batch scheduler offers
reservation capabilities and two ways to requests nodes: either in
interactive mode (you are logged on the first node) or in a passive
mode (a script is batched). The information provided is this trace is
extracted from the OAR database of each site (see http://oar.imag.fr
for the database scheme). Grid'5000 also provides a grid resource
broker, called OARGrid, which allows manual coallocation of resources
using reservation capabilities of OAR. OARGrid also uses a database
which contains pointers to information of individual OAR job of each
site used in a coallocated job. Note that most clusters of Grid'5000
were made available during the first half of 2005. Also note that
there is 10 groups in Grid'5000 each belonging to a site, except for 1
called guest group (group10). 

Grid'5000 Web site: http://www.grid5000.org/

Trace description: TextFile.[log|map]|SQLiteTableName

- grid5000_clean_trace|Jobs: contains the trace of Grid'5000 (all OAR databases information about jobs) from the beginning of the project up to the 10th of November 2006.
  WARNINGs: - some jobs may have wait time of < 0 due to the scheduler behavior (OAR) especially reservations, 
	      e.g., a reservation for the period 8am-2pm can be submitted at 8:01am the same day, for a wait time of -1 min.
	      (see also grid5000_reservation_jobs|Jobs_Reservation)
	    - the trace also includes jobs that have NOT run on Grid'5000, e.g., but canceled before resources are actually allocated to them. 
	      Is up to you to filter these jobs (fields WaitTime=-1 and RunTime=-1)
	    - in the trace some jobs that runned on Grid'5000 are missing, because they were deleted from OAR databases 
	      (see description of the trace on the GWA website for numbers)
	    - all accounts/groups which have submitted jobs are included in the trace (including special administrators, local and guest accounts)
	    - the default requested time (field ReqTime) for a job is 1 hour (3600 seconds)
	    - the application names in the trace are extracted from the original workload using patterns. 
	      For instance, note that 'app1' represents all applications that fit a certain pattern, even if their names are slightly different 
	    - whenever possible local accounts are mapped on grid accounts, 
	      e.g, if a user has a local account 'user1' on site 1 and an account on Grid'5000 (grid account 'user2'), 
	      then only user2 is recorded in the trace for all jobs submitted by this user (either through is local account or its grid account)
	    - correct queue names (field queueID) are: queue0, queue1, queue2, queue7 and queue84. Other are erroneous queue names

- grid5000_coallocated_jobs|CoAllocatedJobs: extended information related to co-allocated jobs (informations coming from OARGrid)
  WARNINGs: - the trace misses some jobs that were coallocated on Grid'5000 through OARGrid, because corresponding OAR jobs have been removed from OAR databases
	    - this trace is based on OARGrid input information only, more coallocated jobs are probably submitted directly by OAR users,
	      e.g., through the use of simultaneous reservations on several OAR sites
	  
- grid5000_interactive_jobs|Jobs_Interactive: extended information related to interactive jobs (list of job ids of interactive jobs)

- grid5000_reservation_jobs|Jobs_Reservation: extended information related to reservations (list of job ids of reservations + start time and stop time of reservations)
  WARNINGs: - be cautious about the use of reservations in this table: the start time of the job can be whatever as it is set by the user. 
	      Especially, start time can be before submit time as this is allowed by OAR.
	    - stop time is equals to -1 when the reservation has been canceled before its start time
	    - start time or end time above the 1st of January 2007 are put as -1, since they are incorrect: the trace was acquired on November 10th 2006.

- grid5000_sites_time|SitesTime: extended information related to times for sites (site id + time zone of the site id + first time a job has been submitted to this site)

- grid5000_user_to_group|Jobs_UserToGroupMap: extended information about user to group matching (user id + group id)

Acknowledgments:

We thank the Grid'5000 team (especially Dr. Franck Cappello) and the
OAR team (especially Dr. Olivier Richard and Nicolas Capit) for making
available the Grid'5000 traces.
	    