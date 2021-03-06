//<?php
/**
 * switchLang
 * 
 * MultiLang swith snippet
 *
 * @author	    webber (web-ber12@yandex.ru)
 * @category 	snippet
 * @version 	0.1
 * @license 	http://www.gnu.org/copyleft/gpl.html GNU Public License (GPL)
 * @internal	@properties lang_template_id=id шаблона языка;text;11 &currlang=язык по умолчанию;text;ru
 * @internal	@modx_category MultiLang
 * @internal    @installset base, sample
 */

// значения по умолчанию на вкладке Свойства - &lang_template_id=id шаблона языка;text;11 &currlang=язык по умолчанию;text;ru

//использование - вызываем в самом верху сайта [[switchLang? &id=`[*id*]`]]
// это нужно, т.к. переводы пишем в сессию и они должны быть до того, как мы к ним обратимся
// в нужном месте прописываем [+activeLang+] (вывод текущего языка) и [+switchLang+] - вывод переключалки (списка) языков
// параметры вызова
	// &activeLang - шаблон вывода текущего языка (отдельно)
	// &activeRow - шаблон вывода текущего языка в списке языков
	// &unactiveRow - шаблон вывода языков в списке (кроме текущего)
	// &langOuter - шаблон обертки для списка языков



//шаблоны вывода по умолчанию
//активный язык отдельно
$activeLang=isset($activeLang)?$activeLang:'<div id="curr_lang"><img src="assets/images/langs/flag_[+alias+].jpg"> <a href="javascript:;">[+name+]</a> <img src="site/imgs/lang_pict.jpg" alt="" id="switcher"></div>'; 
//активный язык в списке
$activeRow=isset($activeRow)?$activeRow:'<div class="active"><img src="assets/images/langs/flag_[+alias+].jpg"> &nbsp;<a href="[+url+]">[+name+]</a></div>';
//неактивный язык списка
$unactiveRow=isset($unactiveRow)?$unactiveRow:'<div><img src="assets/images/langs/flag_[+alias+].jpg"> &nbsp;<a href="[+url+]">[+name+]</a></div>';
//обертка списка языков
$langOuter=isset($langOuter)?$langOuter:'<div class="other_langs">[+wrapper+]</div>';


$content_table=$modx->getFullTableName('site_content');
$tvs_table=$modx->getFullTableName('site_tmplvar_contentvalues');
$out='';
$langs=array();
$others=array();//массив других языков (кроме текущего)

include_once 'assets/snippets/evoBabel/functions.evoBabel.php';
$siteLangs=getSiteLangs($lang_template_id);
$curr_lang_id=getCurLangId($id);
$relations=getRelations($id);
$relArray=getRelationsArray($relations);


//устанавливаем текущий язык
$currLang=str_replace(array('[+alias+]','[+name+]'),array($siteLangs[$curr_lang_id]['alias'],$siteLangs[$curr_lang_id]['name']),$activeLang);

//устанавливаем список языков с учетом активного
$langRows='';
foreach($siteLangs as $k=>$v){
	$tpl=($k!=$curr_lang_id?$unactiveRow:$activeRow);
	if(isset($relArray[$v['alias']])&&checkActivePage($relArray[$v['alias']])){//если есть связь и эта страница активна
		$url=$relArray[$v['alias']];
	}
	else{//нет связи либо страница не активна -> проверяем родителя
		$parent_id=$modx->db->getValue($modx->db->query("SELECT parent FROM {$content_table} WHERE id={$id} AND published=1 AND deleted=0 AND parent!=0 AND template!=$lang_template_id"));
		if(!$parent_id){//если нет родителя, отправляем на главную страницу языка
			$url=$k;	
		}
		else{//если родитель есть, проверяем его связи
			$parent_relations=getRelations($parent_id);
			$relParentArray=getRelationsArray($parent_relations);
			if(isset($relParentArray[$v['alias']])&&checkActivePage($relParentArray[$v['alias']])){//у родителя активная связь
				$url=$relParentArray[$v['alias']];
			}
			else{//иначе -> на главную страницу языка
				$url=$k;
			}
		}
	}
	$langRows.=str_replace(array('[+alias+]','[+url+]','[+name+]'),array($v['alias'],$modx->makeUrl($url),$v['name']),$tpl);
}
$langsList.=str_replace(array('[+wrapper+]'),array($langRows),$langOuter);

// устанавливаем плейсхолдеры [+activeLang+] и [+switchLang+] для вывода активного языка и списка языков соответственно
$modx->setPlaceholder("activeLang",$currLang);
$modx->setPlaceholder("switchLang",$langsList);


//получаем массив перевода для чанков в сессию
$perevod=array();
$cur_lexicon=$siteLangs[$curr_lang_id]['alias'];
$q=$modx->db->query("SELECT * FROM ".$modx->getFullTableName('lexicon'));
while($row=$modx->db->getRow($q)){
	$perevod[$row['name']]=$row[$cur_lexicon];
}
$_SESSION['perevod']=$perevod;
