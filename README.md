# Boston 311 Request Time Series Dashboard

**This dashboard was a simple experiment of mine in RShiny to see if I could plot basic time series information interactively using RShiny.**

* The data for the Boston 311 Request dataset can be downloaded [here](https://data.cityofboston.gov/City-Services/311-Service-Requests/awu8-dc52). I've also included an .rds file in this repo which is the same data.

The methodology of this project was straight forward. For a given neighborhood, what type of requests were made, and what was the duration it took to close that request across the years of the collected data (2011-Present)?

One thing I'm currently working on is incorporating time-series analyses with this data. Right now, a pretty crude implementation of ARIMA forecasting is used, but this will hopefully be improved upon in the future.

First, I subset the data such that I only looked at requests that have been closed. From there, I calculated the duration it took to close the request, in **hours**. Note that request times were aggregated by **week**. 

Line plots were rendered using `plotly`. Plotly is nice in that it allows you to directly interact with the line plot. You can click on the legend to add and hide lines, and you can hover over each line to get the date and values for that data point.

In the RShiny app, you can select the neighborhood, and the department the request went to. You can also set a date range with the sliders, and the plots will automatically re-render with the appopriate range. Four lines are shown: the mean request time, the rolling mean (which aggregates the prior 2 months / 8 weeks of data), the standard error of request times by week, and the count of requests by week.

[You can see the app live on shinyapps.io by clicking here](https://michelletat.shinyapps.io/bos_311/) (but it's really slow so I suggest downloading it and running it locally).