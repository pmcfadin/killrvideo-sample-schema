DROP KEYSPACE IF EXISTS killrvideo;
CREATE KEYSPACE killrvideo WITH REPLICATION = { 'class' : 'SimpleStrategy', 'replication_factor' : 1 };

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

// User Defined Type
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
