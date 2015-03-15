// Sample queries for Apache Cassandra 2.1 version of schema

use killrvideo;

//User select statements
// Select all users. Will be limited to 1000 rows. Rows returned in a random order.
SELECT *
FROM users;

// Select on a specific user. Result set will contain first and last name
SELECT firstname, lastname
FROM users
WHERE userid = d0f60aa8-54a9-4840-b70c-fe562b68842b;

// Video select statements.

// Select everything from a specific video based on ID. Note the format for UUID and it is not quoted.
SELECT *
FROM videos
WHERE videoId = 06049cbb-dfed-421f-b889-5f649a0de1ed;

// Select set collection. Only the entire set can be returned.
SELECT tags
FROM videos
WHERE videoid = 06049cbb-dfed-421f-b889-5f649a0de1ed;

// Select map collection. Individual elements can be returned.
SELECT location
FROM videos
WHERE videoid = 06049cbb-dfed-421f-b889-5f649a0de1ed;

// Username->video index. With more fields in the PRIMARY KEY declaration,
// we can do a variety of interesting queries.
// Lookup video by username
SELECT name,videoID,added_date
FROM user_videos
WHERE userid = 9761d3d7-7fbd-4269-9988-6cfd4e188678;

// Lookup video but ORDER BY the upload date
SELECT name,videoID,added_date
FROM user_videos
WHERE userid = 9761d3d7-7fbd-4269-9988-6cfd4e188678
ORDER BY added_date;

// Lookup video and reverse sort upload date but ORDER BY
SELECT name,videoID,added_date
FROM user_videos
WHERE userid = 9761d3d7-7fbd-4269-9988-6cfd4e188678
ORDER BY added_date DESC;

// Lookup last video uploaded by reverse sorting upload date and limiting results;
SELECT name,videoID,added_date
FROM user_videos
WHERE userid = 9761d3d7-7fbd-4269-9988-6cfd4e188678
ORDER BY added_date DESC
LIMIT 1;

// Lookup video by username and upload date greater than June 6, 2013
SELECT name,videoID,added_date
FROM user_videos
WHERE userid = 9761d3d7-7fbd-4269-9988-6cfd4e188678
AND added_date > '2013-06-01';

// Lookup video by username and upload date between May 15, 2013 and July 1, 2013
SELECT name,videoID,added_date
FROM user_videos
WHERE userid = 9761d3d7-7fbd-4269-9988-6cfd4e188678
AND added_date > '2013-05-15'
AND added_date < '2013-07-01';

// Lookup video by username and upload date between May 15, 2013 and July 1, 2013 and order results
SELECT name,videoID,added_date
FROM user_videos
WHERE userid = 9761d3d7-7fbd-4269-9988-6cfd4e188678
AND added_date > '2013-05-15'
AND added_date < '2013-07-01'
ORDER BY added_date;

// Video rating selects
// Select counter fields. Divide rating_total by rating_counter to get average rating.
SELECT rating_counter, rating_total
FROM video_rating
WHERE videoId = 99051fe9-6a9c-46c2-b949-38ef78858dd0;

// Tag index
// Find a list of videos by tag
SELECT videoID, tagged_date
FROM videos_by_tag
WHERE tag = 'lol';

// Video comments. We have stored this many-to-many in two different fields.
// We will query on either table based on which view we want.
// From the side of comments by video
// All comments for a video
SELECT userid, comment, dateOf(commentid)
FROM comments_by_video
WHERE videoid = 99051fe9-6a9c-46c2-b949-38ef78858dd0;

// Last comment made on a video
SELECT userid, comment, dateOf(commentid)
FROM comments_by_user
WHERE userid = d0f60aa8-54a9-4840-b70c-fe562b68842b
LIMIT 1;

// From the side of comments by userid
// Specific comments for a video by one user
SELECT userid, comment, dateOf(commentid)
FROM comments_by_user
WHERE userid = d0f60aa8-54a9-4840-b70c-fe562b68842b;

// Video event. Time series
// Select all events for a particular video and user combination
SELECT dateOf(event_timestamp), event, video_timestamp
FROM video_event
WHERE videoID = 99051fe9-6a9c-46c2-b949-38ef78858dd0
AND userid= d0f60aa8-54a9-4840-b70c-fe562b68842b;

// Get the last 5 video events
SELECT dateOf(event_timestamp), event, video_timestamp
FROM video_event
WHERE videoID = 99051fe9-6a9c-46c2-b949-38ef78858dd0
AND userid= d0f60aa8-54a9-4840-b70c-fe562b68842b
limit 5;
