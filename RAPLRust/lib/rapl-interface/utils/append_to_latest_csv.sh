# Update last benchmark csv to include timestamp and mv to appropriate dir

#finding latest csv file
FILE=$(ls -t | grep csv | head -1)

# append string to name
timestamp=$(date +%s)
echo $FILE
mv $FILE "results/${FILE%.csv}_$1_$timestamp.csv"
