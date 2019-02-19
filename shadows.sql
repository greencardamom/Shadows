USE enwiki_p;
SELECT wp.page_id, CONCAT("File:",wp.page_title) as page_title FROM image wi
INNER JOIN commonswiki_p.image ci ON ci.img_name = wi.img_name AND ci.img_sha1 != wi.img_sha1
INNER JOIN page wp ON wp.page_title = wi.img_name AND wp.page_namespace = 6
INNER JOIN commonswiki_p.page cp ON cp.page_title = ci.img_name AND cp.page_namespace = 6
LEFT JOIN templatelinks wt ON wt.tl_from = wp.page_id AND wt.tl_namespace = 10 AND wt.tl_title IN
  ('ShadowsCommons',
   'Shadows_commons',
   'Shadows_Commons',
   'Now_Commons',
   'NowCommons',
   'Nowcommons',
   'NowCommonsThis',
   'Now_commons',
   'CommonsNow',
   'NC',
   'NCT',
   'Nct',
   'Db-now-commons',
   'Db-nowcommons',
   'Uploaded to Commons',
   'Pp-template',
   'Keep_local_high-risk',
   'Pp-upload',
   'C-uploaded',
   'C-upload',
   'C uploaded',
   'C-uploaded',
   'M-protected',
   'Main page protected',
   'Mpimgprotected',
   'Mprotect',
   'Mprotected',
   'PP-main',
   'PP-main-page',
   'PP-mainpage',
   'ProtectedMainPageImage',
   'Uploaded_from_Commons',
   'Protected_sister_project_logo',
   'Rename_media',
   'lfr',
   'Image_move',
   'Media_rename',
   'Rename_file',
   'Rename_image',
   'Rename-image',
   'Rename_media',
   'RenameMedia',
   'Renamemedia',
   'Ffd',
   'FFD',
   'lfd',
   'Imagevio',
   'PUF',
   'Puf',
   'PUi',
   'Pui',
   'PUIdisputed'
  )
LEFT JOIN commonswiki_p.templatelinks ct ON ct.tl_from = cp.page_id AND ct.tl_namespace = 10 AND ct.tl_title = 'Deletion_template_tag'
WHERE wt.tl_from IS NULL
AND ct.tl_from IS NULL

