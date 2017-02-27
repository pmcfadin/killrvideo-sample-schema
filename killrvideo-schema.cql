// Sample schema for Apache Cassandra

// IF EXISTS added for Cassandra 2.1
// CQL 3.1.0
DROP KEYSPACE IF EXISTS killrvideo;
CREATE KEYSPACE killrvideo WITH REPLICATION = { 'class' : 'SimpleStrategy', 'replication_factor' : 3 };

use killrvideo;

// User credentials, keyed by email address so we can authenticate
// Seperated from user in case auth is external (Google, Facebook, etc...)
CREATE TABLE user_credentials (
   email text,
   password text,
   userid uuid,
   PRIMARY KEY (email)
);

// Basic entity table for a user
// UUID for userid to link to auth system
CREATE TABLE users (
   userid uuid,
   firstname varchar,
   lastname varchar,
   email text,
   created_date timestamp,
   PRIMARY KEY (userid)
);

// CQL
// Create an index on first name in users table.
// NonTokenizingAnalyzer is used for only match equality
// making it case_sensitive false eliminates any normalization problems.
CREATE CUSTOM INDEX ON users (firstname)
USING 'org.apache.cassandra.index.sasi.SASIIndex'
WITH OPTIONS = {
  'analyzer_class':
  'org.apache.cassandra.index.sasi.analyzer.NonTokenizingAnalyzer',
  'case_sensitive': 'false'
};

// SASI Index on lastname supports a LIKE '%term%' query
// with the mode: CONTAINS
CREATE CUSTOM INDEX ON users (lastname)
USING 'org.apache.cassandra.index.sasi.SASIIndex'
WITH OPTIONS = {'mode': 'CONTAINS'};

// SASI Index on email is for the same type of query as lastname
CREATE CUSTOM INDEX ON users (email)
USING 'org.apache.cassandra.index.sasi.SASIIndex'
WITH OPTIONS = {'mode': 'CONTAINS'};

// SASI Index using mode SPARSE is good for unique, dense number ranges
// and is best for range queries on timestamps
CREATE CUSTOM INDEX ON users (created_date)
USING 'org.apache.cassandra.index.sasi.SASIIndex'
WITH OPTIONS = {'mode': 'SPARSE'};

// User Defined Type introduced in CQL 3.2 spec
// Meta data - Height, Width, Bit rate, Encoding
CREATE TYPE video_metadata (
   height int,
   width int,
   video_bit_rate set<text>,
   encoding text
);

// Entity table that will store many videos for a unique user
CREATE TABLE videos (
   videoid uuid,
   userid uuid,
   name varchar,
   description varchar,
   location text,
   location_type int,
   preview_thumbnails map<text,text>,  // <position in video, url of thumbnail>
   tags set<varchar>,
   metadata set <frozen<video_metadata>>,
   added_date timestamp,
   PRIMARY KEY (videoid)
);

// CQL 3.2 spec included secondary indexes of collections
// These are not for speed but convenience
CREATE INDEX tags_idx ON videos(ENTRIES(tags)); 

// CQL 3.4 spec introduced MATERIALIZED VIEWS
CREATE MATERIALIZED VIEW videos_by_location
AS SELECT userid, added_date, videoid, location
FROM videos
WHERE videoId IS NOT NULL AND location IS NOT NULL
PRIMARY KEY(location, videoid);

// One-to-many from the user point of view
// Also know as a lookup table
CREATE TABLE user_videos (
   userid uuid,
   added_date timestamp,
   videoid uuid,
   name text,
   preview_image_location text,
   PRIMARY KEY (userid, added_date, videoid)
) WITH CLUSTERING ORDER BY (added_date DESC, videoid ASC);

// Track latest videos, grouped by day (if we ever develop a bad hotspot from the daily grouping here, we could mitigate by
// splitting the row using an arbitrary group number, making the partition key (yyyymmdd, group_number))
CREATE TABLE latest_videos (
   yyyymmdd text,
   added_date timestamp,
   videoid uuid,
   name text,
   preview_image_location text,
   PRIMARY KEY (yyyymmdd, added_date, videoid)
) WITH CLUSTERING ORDER BY (added_date DESC, videoid ASC);

// Counter table
CREATE TABLE video_rating (
   videoid uuid,
   rating_counter counter,
   rating_total counter,
   PRIMARY KEY (videoid)
);

// CQL 3.3 adds user defined functions
// This function takes the counters in the video rating table and averages them
// by dividing rating total by rating counter.
CREATE OR REPLACE FUNCTION avg_rating (rating_counter counter, rating_total counter)
CALLED ON NULL INPUT
RETURNS double
LANGUAGE java AS 'return Double.valueOf(rating_total.doubleValue()/rating_counter.doubleValue());';

// Video ratings by user (to try and mitigate voting multiple times)
CREATE TABLE video_ratings_by_user (
   videoid uuid,
   userid uuid,
   rating int,
   PRIMARY KEY (videoid, userid)
);

// Index for tag keywords
CREATE TABLE videos_by_tag (
   tag text,
   videoid uuid,
   added_date timestamp,
   name text,
   preview_image_location text,
   tagged_date timestamp,
   PRIMARY KEY (tag, videoid)
);

// Inverted index for tags by first letter in the tag
CREATE TABLE tags_by_letter (
   first_letter text,
   tag text,
   PRIMARY KEY (first_letter, tag)
);

// Comments as a many-to-many
// Looking from the video side to many users
CREATE TABLE comments_by_video (
   videoid uuid,
   commentid timeuuid,
   userid uuid,
   comment text,
   PRIMARY KEY (videoid, commentid)
) WITH CLUSTERING ORDER BY (commentid DESC);

// looking from the user side to many videos
CREATE TABLE comments_by_user (
   userid uuid,
   commentid timeuuid,
   videoid uuid,
   comment text,
   PRIMARY KEY (userid, commentid)
) WITH CLUSTERING ORDER BY (commentid DESC);


// Time series wide row with reverse comparator
CREATE TABLE video_event (
   videoid uuid,
   userid uuid,
   preview_image_location text static,
   event varchar,
   event_timestamp timeuuid,
   video_timestamp bigint,
   PRIMARY KEY ((videoid,userid),event_timestamp,event)
) WITH CLUSTERING ORDER BY (event_timestamp DESC,event ASC);

// Pending uploaded videos by id
CREATE TABLE uploaded_videos (
    videoid uuid,
    userid uuid,
    name text,
    description text,
    tags set<text>,
    added_date timestamp,
    jobid text,
    PRIMARY KEY (videoid)
);

// Same as uploaded_videos just keyed by the encoding job's id
CREATE TABLE uploaded_videos_by_jobid (
    jobid text,
    videoid uuid,
    userid uuid,
    name text,
    description text,
    tags set<text>,
    added_date timestamp,
    PRIMARY KEY (jobid)
);

// Log of notifications from Azure Media Services encoding jobs (latest updates first)
CREATE TABLE encoding_job_notifications (
    jobid text,
    status_date timestamp,
    etag text,
    newstate text,
    oldstate text,
    PRIMARY KEY (jobid, status_date, etag)
) WITH CLUSTERING ORDER BY (status_date DESC, etag ASC);
