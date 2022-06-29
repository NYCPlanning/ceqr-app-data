---
name: Publish Dataset
about: Move dataset from staging environment to production environment
title: publish {{ env.dataset }}
labels: publish
---

A fresh run of {{ env.dataset }} is complete! 🎉
## Staging files output:
- [ ] [version.txt](https://nyc3.digitaloceanspaces.com/edm-publishing/ceqr-app-data-staging/${{ env.dataset }}/latest/version.txt)
- [ ] [${{ env.dataset }}.zip](https://nyc3.digitaloceanspaces.com/edm-publishing/ceqr-app-data-staging/${{ env.dataset }}/latest/${{ env.dataset }}.zip)
- [ ] [${{ env.dataset }}.csv](https://nyc3.digitaloceanspaces.com/edm-publishing/ceqr-app-data-staging/${{ env.dataset }}/latest/${{ env.dataset }}.csv)
## Next Steps: 
If you have manually checked above files and they seem to be ok, comment `[publish]` under this issue. 
This would allow github actions to move staging files to production. 
Feel free to close this issue once it's all complete. Thanks!
