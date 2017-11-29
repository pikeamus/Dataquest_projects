
filename csvin '\\s20dcp02digdc2\data\Users\F38263\sas training\cars.csv' ;

/*Load the data*/

data  cars ;

	length symboling 8 normalized_losses $3 make $30 fuel_type $10 aspiration $10 doors $10 body_style $20
			drive_wheels $10 engine_location $10 wheel_base 8 length 8 width 8 height 8 curb_weight 8
			engine_type $30 cylinders $30 engine_size 8 fuel_system $30 bore $30 stroke $30
			compression_ratio 8 horsepower $30 peak_rpm $30 city_mpg 8 highway_mpg 8 price $30 ;
	infile csvin missover firstobs=1 dlm=',' DSD ;
	input symboling normalized_losses $ make $ fuel_type $ aspiration $ doors $ body_style $
			drive_wheels $ engine_location $ wheel_base length width height curb_weight 
			engine_type $ cylinders $ engine_size fuel_system $ bore $ stroke $
			compression_ratio horsepower $ peak_rpm $ city_mpg highway_mpg price $ ;

run ;

/*Making some macro variables in order to process columns in bulk*/
/*List of columns in the dataset*/
proc sql noprint;
select name  into :cols separated by ' '
from dictionary.columns
where memname = 'CARS' and type = 'char' ;

/*Count of columns (i.e. number of elements in the list).*/
select count(name) into :col_cnt separated by ' '
from dictionary.columns
where memname = 'CARS' and type = 'char' ;
quit ;

/*Specific columns that are strings currently but should be numeric.*/
/*Also a second list to use for converting (will be renamed back after conversion)*/
%let num_cols = normalized_losses bore stroke horsepower peak_rpm price ;
%let num2 = normalized_losses2 bore2 stroke2 horsepower2 peak_rpm2 price2 ;
%let num_c_cnt = 6 ;


/*Doing the conversions in a macro so we can use out lists.*/

%macro data_cleaning();
/*	First replacing ? with .*/
	data cars2 ;

		set cars ;

		%do i = 1 %to &col_cnt ;
			if %sysfunc(scan(&cols,&i)) = '?' then do;
				%sysfunc(scan(&cols,&i)) = '.' ;
			end ;
		%end ;

	run ;

/*	The doors columns is in words when we want it numeric. Format to change it.*/
	proc format ;
		value $doorsf 'two' = 2
					'four' = 4
					'.' = . ;
	run ;


/*	Then converting selected columns from char to numeric*/

/*	We drop the old character columns and rename the new numeric columns in the data options.*/
	data cars3 (drop= doors &num_cols rename=(doors2 = doors 
						%do k = 1 %to &num_c_cnt ;
							%sysfunc(scan(&num2,&k)) = %sysfunc(scan(&num_cols,&k))
						%end ;
						)) ;

		set cars2 ;
/*			Loop through the six identified columns and create numeric versions.*/
			%do j = 1 %to &num_c_cnt ;
				%sysfunc(scan(&num2,&j)) = input(%sysfunc(scan(&num_cols,&j)),8.) ;
			%end ;
		
/*		And also apply the format to doors, then create a numeric column using the format value.*/
		format doors $doorsf. doors2 8.;
		doors2 = vvalue(doors) ;
		 
	run ;



/*	We will replace the null values in normalized_losses with the mean value for the field.*/
/*	First we need to capture that value in a macro variable.*/
	proc sql noprint ;
		select sum(normalized_losses)/count(normalized_losses) into :avg_nl
		from cars3 ;
	quit ;



/*	Doing the replacement*/
	data cars ;
		set cars3 ;
		if normalized_losses = . then do;
			normalized_losses = &avg_nl ;
		end ;

/*		For other columns, we'll drop rows that include nulls.*/
		if price ne .;
		if bore ne .;
		if horsepower ne .;

/*		For doors, we'll default to 4.*/
		if doors = . then doors = 4 ;

/*		We need to randomize our row order to remove bias from the model later. For that we'll use a random val column.*/
		sortval = rand('UNIFORM') ;
	run ;

%mend ;

%data_cleaning() ;

/*Now we'll normalize the numeric functions, and create a numeric only dataset to use for modelling*/
proc sql noprint;
	select lowcase(name) into :cols2 separated by ' '
	from dictionary.columns
	where libname = 'WORK' and memname = 'CARS' and type = 'num' and upcase(name) not in ('SORTVAL','PRICE');
quit ;

/*This proc will subtract the mean of each column from each value, standardizing it to a mean of zero.*/
proc standard data=cars (keep= &cols2 price) mean= 0 std=1 out=normalized_cars;
	var &cols2;
run ;


/*	Randomize the dataset*/
proc sort data=cars ;
	by sortval ;
run ;

%let endrow = 160 ;

/*View for training set*/
data trainv/view=trainv ;
	set cars ;
	dummy = 1 ;
	if _n_ < &endrow ;
run ;

/*View for test set*/
data testv/view=testv ;
	set cars ;
	dummy = 1 ;
	if _n_ >= &endrow ;
run ;
