create tablespace killrvideo 
datafile 'killrvideo.dat'
size 10M autoextend on;

drop table users cascade constraints;

drop sequence users_sequence; 

drop table video_metadata cascade constraints;

drop table videos cascade constraints;

drop table video_video_metadata cascade constraints;

drop table tags cascade constraints;

drop table videos_tags cascade constraints;

drop table preview_thumbnails cascade constraints;

drop table comments cascade constraints;

drop table video_event cascade constraints;


CREATE TABLE users (
   id           number(12) NOT NULL ,
   firstname    nvarchar2(25) NOT NULL ,
   lastname     nvarchar2(25) NOT NULL,
   email        nvarchar2(50) NOT NULL,
   password     nvarchar2(255) NOT NULL,
   created_date timestamp(6),
   PRIMARY KEY (id),
   CONSTRAINT email_uq UNIQUE (email)
);

-- Sequence for user.id
CREATE SEQUENCE users_sequence
      INCREMENT BY 1
      START WITH 1
      NOMAXVALUE
      NOCYCLE
      CACHE 10;
      
-- Users by email address index
CREATE INDEX idx_users_email ON users (email);

CREATE TABLE video_metadata (
   id       number(12), 
   height   number(10),
   width    number(10),
   video_bit_rate nvarchar2(20),
   encoding nvarchar2(20),
   CONSTRAINT video_metadata_uq UNIQUE (height, width, video_bit_rate, encoding),
   PRIMARY KEY (id)
);

CREATE TABLE videos (
   id number(12),
   userid number(12) NOT NULL,
   name nvarchar2(255),
   description nvarchar2(500),
   location nvarchar2(255),
   location_type int,
   added_date timestamp,
   CONSTRAINT users_userid_fk FOREIGN KEY (userid) REFERENCES users (Id) ON DELETE CASCADE,
   PRIMARY KEY (id)
);

CREATE INDEX idx_videos_userid ON videos (userid);
CREATE INDEX idx_videos_added_date ON videos (added_date);

CREATE TABLE video_video_metadata(
   videoid NUMBER(12),
   videometadataId NUMBER(12),
   CONSTRAINT videos_videoId_fk FOREIGN KEY (videoId) REFERENCES videos (Id) ON DELETE CASCADE,
   CONSTRAINT videos_videometadata_id_fk FOREIGN KEY (videometadataId) REFERENCES video_metadata (id) ON DELETE CASCADE,
   PRIMARY KEY(videoId,videometadataId)
);

CREATE TABLE tags (
   id number(12) PRIMARY KEY,
   tag nvarchar2(255),
   CONSTRAINT tags_uq UNIQUE (tag)
);


CREATE TABLE videos_tags(
   videoId number(12),
   tagId number(12),
   PRIMARY KEY (videoId, tagID),
   CONSTRAINT videos_tags_videoId_fk FOREIGN KEY (videoId) REFERENCES videos (Id) ON DELETE CASCADE,
   CONSTRAINT videos_tags_tagId_fk FOREIGN KEY (tagId) REFERENCES tags (Id) ON DELETE CASCADE
);

CREATE TABLE preview_thumbnails (
   videoId number(12),
   position nvarchar2(20),
   url nvarchar2(255),
   PRIMARY KEY (videoId, position),
   CONSTRAINT preview_thumbnails_videoId_fk FOREIGN KEY (videoId) REFERENCES videos (Id) ON DELETE CASCADE
);


-- Does a FK constraint add an index??

CREATE TABLE comments (
   id number(12),
   userId number(12),
   videoId number(12),
   comment_text nvarchar2(500),
   comment_time timestamp(6),
   PRIMARY KEY (id),
   CONSTRAINT user_comment_fk FOREIGN KEY (userid) REFERENCES users (Id) ON DELETE CASCADE,
   CONSTRAINT video_comment_fk FOREIGN KEY (videoId) REFERENCES videos (Id) ON DELETE CASCADE
);

-- Order by?
CREATE INDEX idx_comment_time ON comments (comment_time);

CREATE TABLE video_event (
   id number(12),
   userId number(12),
   videoId number(12),
   event nvarchar2(255),
   event_timestamp timestamp(6),
   video_timestamp timestamp(6),
   PRIMARY KEY (id, event_timestamp),
   CONSTRAINT user_video_event_fk FOREIGN KEY (userid) REFERENCES users (Id) ON DELETE CASCADE,
   CONSTRAINT video_video_event_fk FOREIGN KEY (videoId) REFERENCES videos (Id) ON DELETE CASCADE
);

CREATE INDEX idx_video_event ON video_event (event);
