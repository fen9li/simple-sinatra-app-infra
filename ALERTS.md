## UPDATE_ROLLBACK_FAILED

Trying to add `tags` to resources, and stucked with error `UPDATE_ROLLBACK_FAILED` as below:

![cloudformation-stack-01](images/cloudformation-stack-01.png)

## To solve the problem, you need to delete and recreate the stack

```
[fli@192-168-1-10 ~]$ aws2 cloudformation delete-stack --stack-name simple-sinatra-app-dev-stack
[fli@192-168-1-10 ~]$ 
```