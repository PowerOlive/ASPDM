﻿<?php	
	if ($handle = opendir('../packs')) {
		while (false !== ($entry = readdir($handle))) {
			if ($entry != "." && $entry != ".." && $entry != "tmp") {
				echo $entry . "\n";
			}
		}
		closedir($handle);
	}
?>