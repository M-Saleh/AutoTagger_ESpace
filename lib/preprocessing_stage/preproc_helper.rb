#encoding: utf-8
require 'nokogiri'
require 'preprocessing_stage/arabic_normalizer'

#Some CONSTANTs
 
XML_FILE = File.join('', "#{::Rails.root}/arwiki-latest-pages-articles.xml")

LINK_PATTERN = /\[\[([^\[\]:]*)\]\]/
ENGLISH_FORM_PATTERN = /\[\[en:(.*)\]\]/

TASNEEF_PAGE = /^تصنيف:.*/
TAWDE7_PAGE = /^.* \(توضيح\)/ 
TA7WEEL_PAGE = /^#تحويل .*/

REDIRECT_PAGE = /^#REDIRECT .*/

FILES_DIR = 'db'
TITLE_IGNORE = [TASNEEF_PAGE, TAWDE7_PAGE] 
TEXT_IGNORE = [TA7WEEL_PAGE, REDIRECT_PAGE]

# IMPORTING && dOWNLOADING ATTRIBUTES 
DB_USER = 'root'
DB_PASSWORD ='1234'
DOWNLOAD_PAGE = 'http://dumps.wikimedia.org/arwiki/latest/arwiki-latest-page.sql.gz'
DOWNLOAD_PAGE_LINKS= 'http://dumps.wikimedia.org/arwiki/latest/arwiki-latest-pagelinks.sql.gz' 
DOWNLOAD_PAGE_REDIRECT='http://dumps.wikimedia.org/arwiki/latest/arwiki-latest-redirect.sql.gz'
DOWNLOAD_XML_FILE='http://dumps.wikimedia.org/arwiki/latest/arwiki-latest-pages-articles.xml.bz2'
 
CURRENT_ENV_ID = '1'
OTHER_ENV_ID = '1'
DATABSE_NAME='arwiki'
HOST='localhost'
THIN_CONFIG= ''
OTHER_THIN_CONFIG = ''


#Some SQL Statments
  
CREATE_TABLE_Synonyms2=<<EOF
 CREATE TABLE Synonyms2 ( rd_from  int(8) unsigned NOT NULL DEFAULT '0', title varbinary(255) NOT NULL DEFAULT '', rd_title varbinary(255) NOT NULL DEFAULT '', PRIMARY KEY (`rd_from`) );
EOF

CREATE_TABLE_Synonyms1=<<EOF
 CREATE TABLE Synonyms1 ( rd_from  int(8) unsigned NOT NULL DEFAULT '0', title varbinary(255) NOT NULL DEFAULT '', rd_title varbinary(255) NOT NULL DEFAULT '', page_id  int(8) unsigned, PRIMARY KEY (`rd_from`) );
EOF


SOlR_PAGE_TABLE=<<EOF
CREATE TABLE solr_page_tmp
  ( page_id INT(8) UNSIGNED NOT NULL,
    page_title VARCHAR(255) NOT NULL DEFAULT '',
    s_d_title VARCHAR(255) NOT NULL DEFAULT '',
    page_type TINYINT UNSIGNED NOT NULL DEFAULT 0,
    KEY (page_title),
    KEY (s_d_title)
  ) DEFAULT CHARSET=utf8
  ( SELECT page_id, CONVERT(page_title using 'utf8') as 'page_title', CONVERT(page_title using 'utf8') as 's_d_title' FROM page
      WHERE  page_namespace = 0 AND page_title NOT RLIKE '(_?توضيح_?)' AND page_is_redirect = 0
  )
EOF

SOlR_PAGE_TABLE_INSERT_SYNONYMS=<<EOF
INSERT INTO solr_page_tmp (page_id, page_title, s_d_title, page_type)
  (SELECT p.page_id, CONVERT(page.page_title using 'utf8') as 'page_title', p.syn_title, 1  FROM
     (SELECT redirect.rd_from, page.page_id, CONVERT(page.page_title using 'utf8') as 'syn_title' FROM redirect
        JOIN page ON redirect.rd_title = page.page_title
          WHERE page.page_namespace = 0 AND page.page_title NOT RLIKE '(_?توضيح_?)'
     ) p
     JOIN page ON p.rd_from = page.page_id WHERE page.page_namespace = 0 AND page.page_title NOT RLIKE '(_?توضيح_?)'
  )
EOF

LINKS_OUTGOING_COUNT_TABLE=<<EOF
CREATE TABLE page_links_count_outgoing
  ( page_id INT(8) UNSIGNED NOT NULL,
    outgoing MEDIUMINT UNSIGNED NOT NULL DEFAULT 0,
    PRIMARY KEY (page_id)
  )
  ( SELECT page.page_id, count(pagelinks.pl_from) AS 'outgoing' FROM
     page JOIN pagelinks ON page.page_id = pagelinks.pl_from
      WHERE page.page_namespace = 0 AND pagelinks.pl_namespace = 0  GROUP BY page.page_id
   )
EOF


LINKS_INCOMING_COUNT_TABLE=<<EOF
CREATE TABLE page_links_count_incoming
  ( page_id INT(8) UNSIGNED NOT NULL,
    incoming MEDIUMINT UNSIGNED NOT NULL DEFAULT 0,
    PRIMARY KEY (page_id)
  )
  ( SELECT page.page_id, count(pagelinks.pl_from) AS 'incoming' FROM
      page JOIN pagelinks ON page.page_title = pagelinks.pl_title
        WHERE pagelinks.pl_namespace = 0 AND page.page_namespace = 0  GROUP BY page.page_title
  )
EOF

# ignore diambig to disambig cases, almost 25 case
SOLR_PAGE_TABLE_INSERT_DISAMBIGS=<<EOF
INSERT INTO solr_page_tmp (page_id, page_title, s_d_title, page_type)
  (SELECT page.page_id, CONVERT(p.page_title using 'utf8') as 'page_title', CONVERT(p.pl_title using 'utf8') as 's_d_title', 2 FROM
    (SELECT REPLACE(page.page_title,'_(توضيح)','') AS 'page_title', pagelinks.pl_title FROM
       page JOIN pagelinks ON page.page_id = pagelinks.pl_from
          WHERE page.page_namespace = 0 AND pagelinks.pl_namespace = 0 AND page.page_title RLIKE '(_?توضيح_?)'
    ) p
    JOIN page ON page.page_title = p.pl_title WHERE page.page_namespace = 0 AND LOCATE(p.page_title, p.pl_title) <> 0 AND p.pl_title NOT RLIKE '(_?توضيح_?)'
  )
EOF

JOIN_LINK_PROB_WITH_PAGE=<<EOF
  CREATE TABLE link_prop
  ( KEY(label),
    KEY(page_title)
  ) DEFAULT CHARSET=utf8
  (
    SELECT p.page_id, a.page_title, a.label, a.text_occur, a.link_occur FROM link_prop_tmp as a 
      JOIN page as p USING(page_title) WHERE p.page_namespace = 0
  )
EOF

SOLR_PAGE_JOIN_TABLE_LINK_PROP_1=<<EOF
CREATE TEMPORARY TABLE solr_page_tmp_link_prop1
  (SELECT p.page_id,  REPLACE(p.page_title,'_',' ')as 'page_title',  REPLACE(p.s_d_title,'_',' ') as 's_d_title', p.page_type as 'page_type's, l.text_occur, l.link_occur  FROM 
      solr_page_tmp AS p LEFT JOIN link_prop AS l ON (l.label =  REPLACE(p.page_title,'_',' ') and l.page_title =  REPLACE(p.s_d_title,'_',' '))
  )
EOF

SOLR_PAGE_JOIN_TABLE_LINK_PROP_2=<<EOF
CREATE TEMPORARY TABLE solr_page_tmp_link_prop2
  (SELECT l.page_id, l.label as 'page_title', l.page_title as 's_d_title', 1 as 'page_type', l.text_occur, l.link_occur FROM
       solr_page_tmp AS p RIGHT JOIN link_prop AS l on (l.label = REPLACE(p.page_title,'_',' ') and l.page_title =  REPLACE(p.s_d_title,'_',' ')) 
        WHERE p.page_id IS NULL AND l.label NOT RLIKE '(_?توضيح_?)' AND l.page_title NOT RLIKE '(_?توضيح_?)'
  )
EOF

SOLR_PAGE_JOIN_TABLE_LINK_PROP_3=<<EOF
CREATE TABLE solr_page_tmp2
  ( SELECT * FROM 
    ( SELECT * FROM solr_page_tmp_link_prop1
       UNION 
      SELECT * FROM solr_page_tmp_link_prop2
    ) c
  )
EOF

SOLR_PAGE_TABLE_INSERT_SYNONYMS_TO_DIAMBIGS=<<EOF
INSERT INTO solr_page (page_id, page_title, s_d_title, page_type, incoming, outgoing)
  (SELECT s.page_id, a.page_title, s.s_d_title, 2, s.incoming, s.outgoing
    FROM solr_page AS s JOIN
      (SELECT p.page_id, CONVERT(page.page_title using 'utf8') AS 'page_title', p.disambig_title FROM
        (SELECT redirect.rd_from, page.page_id, REPLACE(CONVERT(page.page_title USING 'utf8'),'_(توضيح)','') as 'disambig_title' FROM redirect
          JOIN page ON redirect.rd_title = page.page_title
            WHERE page.page_namespace = 0 AND page.page_title LIKE '%(توضيح)%'
        ) p
        JOIN page ON p.rd_from = page.page_id WHERE page.page_namespace = 0 AND page.page_title NOT RLIKE '(_?توضيح_?)'
      ) a ON s.page_title = a.disambig_title WHERE s.page_type = 2 AND a.page_title <> s.page_title
  )
EOF

# Case2: title_(توضيح) => title_(توضيح), almost 500
SOLR_PAGE_TABLE_INSERT_DISAMBIG_SYNONYMS_TO_DIAMBIGS=<<EOF
INSERT INTO solr_page (page_id, page_title, s_d_title, page_type, incoming, outgoing)
  (SELECT s.page_id, a.page_title, s.s_d_title, 2, s.incoming, s.outgoing
    FROM solr_page AS s JOIN
      (SELECT p.page_id,  REPLACE(REPLACE(CONVERT(page.page_title USING 'utf8'),'_(توضيح)',''), '(توضيح)', '') AS 'page_title', p.disambig_title FROM
        (SELECT redirect.rd_from, page.page_id, REPLACE(CONVERT(page.page_title USING 'utf8'),'_(توضيح)','') AS 'disambig_title' FROM redirect
          JOIN page ON redirect.rd_title = page.page_title
            WHERE page.page_namespace = 0 AND page.page_title LIKE '%(توضيح)%'
        ) p
        JOIN page ON p.rd_from = page.page_id WHERE page.page_namespace = 0 AND page.page_title LIKE '%(توضيح)%'
      ) a ON s.page_title = a.disambig_title WHERE s.page_type = 2  and s.page_title <> a.page_title
  )
EOF

# Case3: title_(توضيح) => title, less common almost 100
SOLR_PAGE_TABLE_INSERT_DISAMBIG_TO_SYNONYMS=<<EOF
INSERT INTO solr_page (page_id, page_title, s_d_title, page_type, incoming, outgoing)
  (SELECT s.page_id, a.page_title, a.syn_title , 1, s.incoming, s.outgoing
    FROM solr_page AS s JOIN
    (SELECT p.page_id, REPLACE(CONVERT(page.page_title USING 'utf8'),'_(توضيح)','') AS 'page_title', p.syn_title FROM
          (SELECT redirect.rd_from, page.page_id, CONVERT(page.page_title USING 'utf8') as 'syn_title' FROM redirect
            JOIN page ON redirect.rd_title = page.page_title
              WHERE page.page_namespace = 0 AND page.page_title NOT LIKE '%(توضيح)%'
          ) p
          JOIN page ON p.rd_from = page.page_id WHERE page.page_namespace = 0 AND page.page_title LIKE '%(توضيح)%'
      ) a ON s.page_title = a.syn_title AND s.page_type = 0  AND s.page_title <> a.page_title
  )
EOF


def drop_english_translation_table_if_exist
ActiveRecord::Base.connection.execute("DROP TABLE IF EXISTS english_translation;")
end

def drop_synonyms1_if_exist
ActiveRecord::Base.connection.execute("DROP TABLE IF EXISTS Synonyms1 ;")
end

def drop_synonyms2_if_exist
ActiveRecord::Base.connection.execute("DROP TABLE IF EXISTS Synonyms2 ;")
end

def drop_page_links_count_incoming_if_exist
ActiveRecord::Base.connection.execute("DROP TABLE IF EXISTS page_links_count_incoming ;")
end

def drop_link_prob_table_if_exist
ActiveRecord::Base.connection.execute("DROP TABLE IF EXISTS link_prop;")
end

def drop_solr_page_tmp2_table_if_exist
ActiveRecord::Base.connection.execute("DROP TABLE IF EXISTS solr_page_tmp2;")
end

def drop_solr_page_tmp_if_exist
ActiveRecord::Base.connection.execute("DROP TABLE IF EXISTS solr_page_tmp;")
end

def create_english_translation_table
ActiveRecord::Base.connection.execute(" 
 create TABLE english_translation
    (
      page_id INT(8) UNSIGNED NOT NULL,
      en_form VARCHAR(255) NOT NULL DEFAULT '',
      PRIMARY KEY (page_id)
    );"
    )
end

def drop_link_prob_temp_table_if_exist
ActiveRecord::Base.connection.execute("DROP TABLE IF EXISTS link_prop_tmp;")
end

def create_link_prob_temp_table
ActiveRecord::Base.connection.execute(  
  "CREATE TABLE link_prop_tmp
  ( 
    label VARCHAR(255) NOT NULL,
    page_title VARCHAR(255) NOT NULL,
    text_occur MEDIUMINT UNSIGNED NOT NULL DEFAULT 0,
    link_occur MEDIUMINT UNSIGNED NOT NULL DEFAULT 0,
    KEY(page_title)
  ) DEFAULT CHARSET=utf8;
  ")
  end    
