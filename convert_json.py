import pandas as pd
import pyarrow as pa
import pyarrow.parquet as pq

# Read JSON into DataFrame
json_data = [{'name': 'Alice', 'age': 30}, {'name': 'Bob', 'age': 25}]
df = pd.DataFrame(json_data)

# Convert DataFrame to Arrow Table
table = pa.Table.from_pandas(df)

# Write Arrow Table to Parquet file
pq.write_table(table, 'output.parquet')