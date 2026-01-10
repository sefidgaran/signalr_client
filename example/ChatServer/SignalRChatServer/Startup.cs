using Microsoft.AspNetCore.Builder;
using Microsoft.AspNetCore.Hosting;
using Microsoft.Extensions.Configuration;
using Microsoft.Extensions.DependencyInjection;
using Microsoft.Extensions.Hosting;

namespace SignalRChatServer
{
  public class Startup
  {
    public Startup(IConfiguration configuration)
    {
      Configuration = configuration;
    }

    public IConfiguration Configuration { get; }

    // This method gets called by the runtime. Use this method to add services to the container.
    public void ConfigureServices(IServiceCollection services)
    {
      services.AddSignalR();
      services.AddCors(options => options.AddPolicy("CorsPolicy",
        builder =>
        {
          builder.AllowAnyHeader()
                  .AllowAnyMethod()
                  .SetIsOriginAllowed((host) => true)
                  .AllowCredentials();
        }));
    }

    // This method gets called by the runtime. Use this method to configure the HTTP request pipeline.
    public void Configure(IApplicationBuilder app, IWebHostEnvironment env)
    {
      if (env.IsDevelopment())
      {
        app.UseDeveloperExceptionPage();
      }
      else
      {
        app.UseExceptionHandler("/Error");
        app.UseHsts();
      }

      //app.UseHttpsRedirection();
      app.UseDefaultFiles();
      app.UseStaticFiles();
      app.UseCookiePolicy();

      app.UseRouting();

      // Apply CORS after routing and before endpoints so hub requests get the CORS headers
      app.UseCors("CorsPolicy");

      app.UseAuthorization();
      app.UseEndpoints(endpoints =>
      {
        endpoints.MapHub<ChatHub>("/Chat");
      });
    }
  }
}
