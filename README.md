# Boston 311 Request Time Series Dashboard

**This dashboard was a simple experiment of mine in RShiny to see if I could plot basic time series information interactively using RShiny.**

* The data for the Boston 311 Request dataset can be downloaded [here](https://data.cityofboston.gov/City-Services/311-Service-Requests/awu8-dc52). I've also included an .rds file in this repo which is the same data.

The methodology of this project was straight forward. For a given neighborhood, what type of requests were made, and what was the duration it took to close that request across the years of the collected data (2011-Present)?

First, I subset the data such that I only looked at requests that have been closed. From there, I calculated the duration it took to close the request, in **hours**. Note that request times were aggregated by **week**. Information was plotted using ggplot2.

In the RShiny app, you can select the neighborhood, and the department the request went to. You can also set a date range with the sliders, and the plots will automatically re-render with the appopriate range. The dashboard currently spit out a two plots, one that shows the mean request time over the years, along with the standard error of each request (in the light blue). The second plot visualizes the number of requests made on a weekly basis.

Finally, you can click on the first plot to get the values, which will be shown in the gray box above it.

[You can see the app live on shinyapps.io by clicking here](https://michelletat.shinyapps.io/bos_311/) (but it's really slow so I suggest downloading it and running it locally) Screen shots of this app are below.

## Screenshots 

**The screenshot below shows the input widgets to select neighborhood and department, as well as slider inputs to set the date range. Plots are shown below for those parameters. You can click on the first plot to get the exact values.**

![alt text](https://raw.githubusercontent.com/mjtat/Boston_311_Dashboard/master/images/screen1.png "Screenshot 1")

**The screenshot shows a different neighborhood and department, with a much smaller date range.**

![alt text](https://raw.githubusercontent.com/mjtat/Boston_311_Dashboard/master/images/screen2.png "Screenshot 2")

**Finally, you can click on the Table tab to view the actual data table that is visualized on the plots.**

![alt text](https://raw.githubusercontent.com/mjtat/Boston_311_Dashboard/master/images/screen3.png "Screenshot 3")