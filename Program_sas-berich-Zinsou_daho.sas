/******************************/
/*     PARTIE I : SAS BASE      /
/******************************/

/*1- Construire une macro fonction nommée << file_import >> qui permet d'importer une table il
doit contenir en paramètre :
- une macro variable qui contient le lien vers le dossier de stockage du fichier
- le nom du fichier et son extension
- le nom de la table en sortie
- le délimiter si nécessaire*/

%macro file_import(folder_path, file_name, table_name, delimiter=,);

   /* Créer le chemin complet du fichier */
   %let full_path = %sysfunc(catx(/, &folder_path., &file_name.));

   /* Importer le fichier en utilisant la procédure IMPORT */
   proc import datafile="&full_path." out=&table_name. dbms=csv replace;
      delimiter=&delimiter.;
      getnames=yes;
   run;

%mend;

/* 2- Utilisez la macro fonction créée dans la question précédente pour importer les 06 fichiers du projet*/

%file_import(/home/u63066612/Advanced SAS/Project_tables,
  file_name=customers.txt, 
  table_name= Customers, delimiter='09'x);

%file_import(/home/u63066612/Advanced SAS/Project_tables,
  file_name=orders.txt, 
  table_name= Orders, delimiter='09'x);
  
%file_import(/home/u63066612/Advanced SAS/Project_tables,
  file_name= order_items.txt, 
  table_name= Orders_items, delimiter='09'x);
  
%file_import(/home/u63066612/Advanced SAS/Project_tables,
  file_name= order_payments.txt, 
  table_name= Orders_payments, delimiter='09'x);
  
%file_import(/home/u63066612/Advanced SAS/Project_tables,
  file_name=products.txt, 
  table_name= Products, delimiter='09'x);
  
%file_import(/home/u63066612/Advanced SAS/Project_tables,
  file_name=products_translation.txt, 
  table_name= Products_translation, delimiter='09'x);


/* 4- Dans une étape Data, créez une table nommée « customers1 » à partir de « customers ».
- Ajoutez-y une nouvelle colonne nommée « anciennete » qui donne l’écart en mois entre la date de résiliation de la carte “cancellation_date” et celle de suscription.
- une nouvelle colonne nommée "state_groupe" qui regroupe les modalites de la variables customer_state ".*/

data work.Customers1;
	set work.Customers;
	attrib anciennete label="anciennete";
	attrib state_group label="state_groupe";
	anciennete = intck('month',card_date_subscription ,cancellation_date);

	if substr(customer_state,1,1) in ("A","B","C","D","E","F","G") then state_groupe = "Groupe 1";
	else if substr(customer_state,1,1) in ("M","N","O","P","Q") then state_groupe = "Groupe 2";
	else state_groupe = "Groupe 3";
run;

proc sort data= work.Customers1;
	by customer_state anciennete;
run;

/*5-a  A l’aide d’une « étape PROC FREQ », donnez l’effectif des clients par “state_groupe” et “anciennete”.
 Sauvegarder le résultat dans une table nommée « customers21 */

proc freq data = work.Customers1;
	tables state_groupe * anciennete/list nopercent  nocum out= work.Customers21 (rename= (COUNT= n_contract) drop=percent);
run;
proc print data= work.Customers21;
run;

/*5-b A l’aide d’une « étape PROC FREQ », donnez par “state_groupe” et “anciennete” le nombre de clients 
ayant résilié (cancellation=1). Sauvegarder le résultat dans une table nommée « customers22 */
proc freq data = work.Customers1;
	tables state_groupe * anciennete /list nopercent nocum out= work.Customers22 (rename= (COUNT=n_resillation) drop=percent);
	where cancellation = 1;
run;
proc print data=work.Customers22;
run;

/*5-c A l’aide d’une « étape PROC FREQ », donnez l’effectif total des clients par “state_groupe”.
 Sauvegarder le résultat dans une table nommée « customers23 */

proc freq data = work.Customers1;
	tables state_groupe/ nopercent nocum out=work.Customers23 (rename= (COUNT= n_cohorte) drop=percent);
run;
proc print data= work.Customers23;
run;

/*6-a A l’aide d’une « étape DATA / merge » créez une table « customers31 » qui fusionne les
tables « customers21 » et « customers22 ». Dans cette même étape « DATA » 
créer une nouvelle colonne qui cumule le nombre de contrats par “state_groupe” et par “anciennete”*/

data work.Customers31 ;
	merge work.Customers21 work.Customers22;
	by state_groupe anciennete;
	retain cum_n_contract 0;
	if First.state_groupe Then cum_n_contract = 0;
	cum_n_contract = cum_n_contract + n_contract ;
run;
proc print data = work.Customers31;
run;

/*6-b A l’aide d’une « étape DATA / merge », créez une table « customers32 » qui fusionne 
les tables « customers23 » et « customers31 ». 
Dans la même étape DATA, par “state_groupe” */

data work.Customers32 ;
	merge work.Customers23 work.Customers31;
	by state_groupe;
	n_risque = n_cohorte + n_contract - cum_n_contract;
	tx_survie = LOG(1 - (n_resillation/n_risque));
	retain estim 0;
	if First.state_groupe Then estim = 0;
	estim = estim + tx_survie ;
	estimateur_survi= exp(tx_survie);
run;
proc print data = work.Customers32;
run;

/******************************/
/*     PARTIE II : SAS SQL      /
/******************************/

/*1- Écrivez le programme SAS qui permet d’obtenir le nombre distinct de clients par groupe 
d'État et par type de carte. Ordonnez les résultats dans l’ordre décroissant
 suivant le nombre de clients. Utiliser la variable « customer_id */

proc sql;
	select 
			loyalty_card_type, state_groupe,  
			count (customer_id) as n_clients
	from work.Customers1
	group by loyalty_card_type, state_groupe
	order n_clients desc;
quit;

/*2-  En partant de la requête précédente, écrivez la requête qui permet d’obtenir le nombre de commandes 
qui ont été passées au mois de juin 2017. Précisez également dans la même requête par combien de clients 
ont-elles été passées. Affichez les résultats par état du consommateur et type de carte de fidélité. 
Ordonnez les résultats dans l’ordre décroissant suivant le nombre de clients.*/

proc sql;
	select 
		YEAR(datepart(A.order_purchase_date)) as annee,
		MONTH(datepart(A.order_purchase_date)) as mois,
		count(distinct (A.order_id)) as n_orders, 
		count ( distinct (B.customer_id)) as n_clients, 
		B.loyalty_card_type, B.customer_state
	from work.orders as A , work.Customers1 as B
	where A.customer_id =B.customer_id
	group by annee, mois, B.loyalty_card_type, B.customer_state
	having annee = 2017 and mois = 6
	order by n_clients desc;
quit;

/*3- Ecrivez le programme SAS qui permet  obtenir pour les produits de poids sup�rieur � 29000, le nombre de commandes concern�s. 
 Afficher le r�sultat suivant le nom des produits en anglais.*/

proc sql;
	select distinct 
			Z.product_category_name_english,
			X.product_weight_g, count (Y.order_id) as value label = "Nombre de commandes"
	from work.products X, work.orders_items Y, work.products_translation Z
	where X.product_id = Y.product_id and X.product_category_name = Z.product_category_name
	group by  X.product_weight_g, Z.product_category_name_english
	having X.product_weight_g > 29000;
quit; 

/*4- Par type de carte de fidélité, affichez le nombre de commandes associées, chiffre d’affaires 
total des commandes, le minimum, moyen et maximum et l’écart type des montants de commandes..
*/

proc sql;
	select 
			A.loyalty_card_type, 
			count(distinct (B.order_id)) as NB_commandes,  
			sum (C.payment_value) as CA_total,
			min(C.payment_value) as CA_min, 
			mean(C.payment_value) as CA_moy, 
			max(C.payment_value) as CA_max, 
			std(C.payment_value) as CA_std
	from work.customers as A, work.orders as B, work.orders_payments as C
	where  A.customer_id =B.customer_id and B.order_id = C.order_id
	group by A.loyalty_card_type;
quit;

/*5-Écrivez la requête SQL qui permet de déterminer pour chaque de État, le chiffre d’affaires total, le nombre de commandes réalisées, 
le panier moyen et le nombre moyen d’UVC..*/

proc sql;
	select 
	A.customer_state,
	sum (C.payment_value) as CA_total, 
	count (distinct(D.order_id)) as NB_commandes, 
	count (distinct (A.customer_id)) as NB_clients,
	count (B.product_id) as NB_produits,
	sum (C.payment_value)/ count (distinct(D.order_id)) as Panier_moyen, 
	count (B.product_id)/ count (distinct(D.order_id)) as NB_uvc
	from work.customers as A, work.orders_items as B, work.orders_payments as C, work.orders as D
	where  A.customer_id = D.customer_id and B.order_id = D.order_id and C.order_id = D.order_id 
	group by A.customer_state
	order by NB_commandes desc
	;
quit;

/*******************************/
/*     PARTIE III : SAS MACRO  */
/*******************************/

/*1 Cr�ation de table */

data work.AS1;
	set work.customers; 
		 i = ranuni(0);
run;

/* Tri des observations en fonction de i */

proc sort data=work.AS1 out = work.AS1;
   by i ;
run;

data work.AS1;
    set work.AS1(obs=5000);
run;

/*2  Programme AS2*/

%let table_entree = work.customers;
%let table_sortie = work.AS2;
%let nb_obs = 5000;

data &table_sortie;
	set &table_entree;
		 i = ranuni(0);
run;

proc sort data=&table_sortie out=&table_sortie;
   by i ;
run;

data &table_sortie;
    set &table_sortie(obs=&nb_obs);
run;

/*3- Programme AS3*/

%let table_entree = work.customers;
%let table_sortie = work.AS3;
%let percent_obs = %sysevalf(20);

data &table_sortie;
	set &table_entree;
		 i = ranuni(0);
run;

proc sort data=&table_sortie out=&table_sortie;
   by i;
run;

data _null_;
		set &table_sortie end = last;
		If last then call symput("nb_obs", _N_);
	run;
	data &table_sortie;
    set &table_sortie(obs = %sysfunc(round(%sysevalf((&percent_obs/100) * &nb_obs),1)));
run;

/*4- Programme AS4*/

%macro as(table_entree, table_sortie, percent_obs);
data &table_sortie;
set &table_entree;
i = ranuni(0);
run;
proc sort data = &table_sortie out = table_sortie;
by i;
run;

	data _null_;
		set &table_sortie end = last;
		If last then call symput("nb_obs", _N_);
	run;

	data &table_sortie;
	    set &table_sortie(obs = %sysfunc(round(%sysevalf((&percent_obs/100) * &nb_obs),1)));
	run;

%mend;

%as(work.customers, work.AS4, 20)


/*PARTIE B */

/*1 Programme ASTR1*/

%macro ASTR(table, var_strati);
ods output  OneWayFreqs =sortie (keep = &var_strati. frequency) ;
proc freq data = work.&table.;   
	table &var_strati./ nopercent nocol norow nocum;
run;

data _null_;
set sortie end = last; 
call symputx (compress("modalite"!!_N_), compress(&var_strati.));
call symputx (compress("freq"!!_N_), compress(Frequency));
If last then call symput("N_modalite",compress( _N_));
run;

%put La variable &var_strati. a &N_modalite. modalit�s : ;
%do i = 1 %to  &N_modalite.;
%put - la modalit� &i. est &&modalite&i.. avec &&freq&i.. effectifs;
%end ;
run;
%mend;
%ASTR(customers, loyalty_card_type );


/*2- Programme ASTR2*/

%macro ASTR2(table, var_strati);
ods output  OneWayFreqs=sortie (keep = &var_strati. frequency) ;
proc freq data = work.&table.;   
	table &var_strati./ nopercent nocol norow nocum;
run;

data _null_;
set sortie end = last; 
call symputx (compress("modalite"!!_N_), compress(&var_strati.));
call symputx (compress("freq"!!_N_), compress(Frequency));
If last then call symput("N_modalite",compress( _N_));
run;

%do i=1 %to &N_modalite;

		data work.&&&modalite&i;

			set work.&table;
			where compress(&var_strati)="&&&modalite&i";

		run;
%end;
%put La variable &var_strati. a &N_modalite. modalit�s : ;
%do i = 1 %to  &N_modalite.;
%put - la modalit� &i. est &&modalite&i.. avec &&freq&i.. effectifs;
%end ;
run;
%mend;
%ASTR2(customers, loyalty_card_type );

/*3- Programme ASTR3 */

%macro ASTR2(table, var_strati, t_echan);
%if &t_echan gt 1 %then %do ;
%let t_echan = %sysevalf(&t_echan/100) ;
%end; 
ods output  OneWayFreqs=sortie (keep = &var_strati. frequency) ;
proc freq data = work.&table.;   
	table &var_strati./ nopercent nocol norow nocum;
run;

data _null_;
set sortie end = last; 
call symputx (compress("modalite"!!_N_), compress(&var_strati.));
call symputx (compress("freq"!!_N_), compress(Frequency));
If last then call symput("N_modalite",compress( _N_));
run;
data work.final;
run;
%do i=1 %to &N_modalite;

		data work.&&modalite&i..;

			set work.&table;
			where compress(&var_strati)="&&modalite&i";

		run;
		data work.&&modalite&i..;
	set work.&&modalite&i..;
	i_t = ranuni(0);
	run;
	proc sort data = work.&&modalite&i;
	by i_t;
	run;
	data work.&&modalite&i.._tx;
	set work.&&modalite&i.;
	n = _N_;
	if n lt &t_echan * &&freq&i then output;
	drop n;
	run;
%end;

%put La variable &var_strati. a &N_modalite. modalit�s : ;
%do i = 1 %to  &N_modalite.;
%put - la modalit� &i. est &&modalite&i.. avec &&freq&i.. effectifs;
%end ;
run;
%mend;
%ASTR2(customers, loyalty_card_type, 33);

/*4- Programme ASTR4 */

%macro ASTR2(table, var_strati, t_echan);
%if &t_echan gt 1 %then %do ;
%let t_echan = %sysevalf(&t_echan/100) ;
%end; 
ods output  OneWayFreqs=sortie (keep = &var_strati. frequency) ;
proc freq data = work.&table.;   
	table &var_strati./ nopercent nocol norow nocum;
run;

data _null_;
	set sortie end = last; 
	call symputx (compress("modalite"!!_N_), compress(&var_strati.));
	call symputx (compress("freq"!!_N_), compress(Frequency));
	If last then call symput("N_modalite",compress( _N_));
run;
data work.final;
run;
%do i=1 %to &N_modalite;

		data work.&&modalite&i..;

			set work.&table;
			where compress(&var_strati)="&&modalite&i";

		run;
		data work.&&modalite&i..;
	set work.&&modalite&i..;
	i_t = ranuni(0);
	run;
	proc sort data = work.&&modalite&i;
	by i_t;
	run;
	data work.&&modalite&i.._tx;
	set work.&&modalite&i.;
	n = _N_;
	if n lt &t_echan * &&freq&i then output;
	drop n;
	run;
data work.final;
set work.final work.&&modalite&i.._tx;
run;
%end;

%put La variable &var_strati. a &N_modalite. modalit�s : ;
%do i = 1 %to  &N_modalite.;
%put - la modalit� &i. est &&modalite&i.. avec &&freq&i.. effectifs;
%end ;
run;
%mend;
%ASTR2(customers, loyalty_card_type, 33);

/******************************FIN********************************/
	
















