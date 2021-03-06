//
//  RecipeListViewController.swift
//  FitMeal
//
//  Created by Mingyang Sun on 7/18/16.
//  Copyright © 2016 MingyangSun. All rights reserved.
//

import UIKit
import Alamofire
import SDWebImage




class RecipeListViewController: UIViewController, UITableViewDelegate{
    @IBOutlet weak var RecipeTableView: UITableView!
    var recipeList:[RecipeCellObject]=[]
    
    let head: [String: String] = [
        "X-Mashape-Key": AppDelegate.head,
        ]
    var progressFinish:Bool=false
    var retreveFinish:Bool=false
 
    @IBOutlet weak var activityIndicator: UIActivityIndicatorView!
    
    @IBOutlet weak var noResultsView: UIView!
    var noResults:Bool=false
    var results:[NSDictionary]?
    var recipeResultDic:NSDictionary?
    var progressView:KDCircularProgress?
    var resultRetrieve:Bool=false
    var cusine:String?
    var diet:String?
    var excludeIngredients:String?
    var includeIngredients: String?
    var intolerances: String?
    var maxCalories:Double?
    var minCalories:Double?
    var maxCarbs:Double?
    var minCarbs:Double?
    var maxProtein:Double?
    var minProtein:Double?
    var maxFat:Double?
    var minFat:Double?
    var query:String?
    var type:String?
    
 
    var imageURL:String=""
    var image:UIImage?
    var titleOfRecipe:String?
    var fatResult:String?
    var caloriesResult:String?
    var carbsResult:String?
    var proteinResult:String?
    var servings:Int?
    var readyTime:Int?
    var missedIngredientsString:String?
    var missedIngredientsCount:Int?
    var idOfRecipe:Int?
    var deleteRecipe:Bool?
    override func viewDidLoad() {
        super.viewDidLoad()
        self.RecipeTableView.delegate = self
        self.RecipeTableView.dataSource = self
        noResultsView.hidden=true
        RecipeTableView.hidden=true
       activityIndicator.startAnimating()
 
     self.getAllResults()
        

    }

    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
        // Dispose of any resources that can be recreated.
    }


    /*
    // MARK: - Navigation

    // In a storyboard-based application, you will often want to do a little preparation before navigation
    override func prepareForSegue(segue: UIStoryboardSegue, sender: AnyObject?) {
        // Get the new view controller using segue.destinationViewController.
        // Pass the selected object to the new view controller.
    }
    */
    func checkNutritions(){
        if(maxCalories == nil){
            maxCalories=5000
        }
        if(minCalories==nil){
            minCalories=5000
        }
        if(maxCarbs == nil){
            maxCarbs=5000
        }
        if(minCarbs == nil){
            minCarbs=0
        }
        if(maxProtein == nil){
            maxProtein=5000
        }
        if(minProtein == nil){
            minProtein=0
        }
        if(maxFat==nil){
            maxFat=5000
        }
        if(minFat == nil){
            minFat=0
        }
    }
    func getAllResults(){
        var parameters = [String:AnyObject]()
        parameters["cusine"] = cusine
        parameters["diet"]=diet
        parameters[ "excludeIngredients"]=excludeIngredients
        parameters["fillIngredients"]=false
        parameters[ "includeIngredients"]=includeIngredients
        parameters ["intolerances"]=intolerances
        parameters["limitLicense"]=true
        checkNutritions()
        parameters[ "maxCalories"]=maxCalories
        parameters[ "maxCarbs"]=maxCarbs
            parameters["maxFat"]=maxFat
         parameters["maxProtein"]=maxProtein
       parameters["minCalories"]=minCalories
          parameters["minCarbs"]=minCarbs
          parameters["minFat"]=minFat
           parameters["minProtein"]=minProtein
         parameters["number"]=5
         parameters["offset"]=0
        parameters["query"]=query
        parameters["ranking"]=1
         parameters["type"]=type
        var servingPeople:Int?
        var readyTimeMinutes:Int?
        Alamofire.request(.GET, "https://spoonacular-recipe-food-nutrition-v1.p.mashape.com/recipes/searchComplex", parameters: parameters, encoding: ParameterEncoding.URL,headers: head) .responseJSON{ response in
            switch response.result{
            case .Success(let value):
                
                let response = value as! NSDictionary
                self.results=response["results"] as? [NSDictionary]
                if (self.results!.isEmpty){
                    self.noResultsView.hidden=false
                    self.RecipeTableView.hidden=true
//                    self.progressView!.hidden=true
                    return
                }
                for recipeResultDic in self.results!{
                    var eachSumRecipe:RecipeCellObject?
                 
                    let title=recipeResultDic["title"] as! String
                    let image=recipeResultDic["image"] as! String
                    let carbs=recipeResultDic["carbs"] as? String ?? ""
                    let calories=recipeResultDic["calories"] as? Int ?? 0
                    let stringRep=String(calories)
                    let protein=recipeResultDic["protein"] as? String ?? ""
                    let fat=recipeResultDic["fat"] as? String ?? ""
                    let Id=recipeResultDic["id"] as? Int ?? 0
                if(InformationInputViewController.dislikeIDsList.contains(Id)){
                        continue
                    }
                    let missedIngredientsCount=recipeResultDic["missedIngredientCount"] as? Int ?? 0
      
   
                    
                    self.getRecipeInformation(Id, callback: { (serving:Int?, readyTime:Int?) in
                        servingPeople=serving!
                        readyTimeMinutes=readyTime!
                         eachSumRecipe=RecipeCellObject(title:title, fat:fat, calories:stringRep, protein:protein, carbs:carbs, image:image, id:Id, readyMinutes:readyTimeMinutes!, servings:servingPeople!,missedIngredientsCount: missedIngredientsCount)
                        self.getStepsInformation(Id, completionHandler:{ (deleteRecipe:Bool) ->Void in
                          
                            if (deleteRecipe==false){
                                
                                self.recipeList.append(eachSumRecipe!)
                                dispatch_async(dispatch_get_main_queue()) {
                                    self.resultRetrieve=true
                                    self.RecipeTableView.reloadData()
                                    self.retreveFinish=true
                                    self.activityIndicator.stopAnimating()
                                    self.RecipeTableView!.hidden=false

                                    
                                }
                            }
                        })

                                          })

                }
            case .Failure(let error):
                print("error:\(error.description)")
            }
        }

    }
    
    func getStepsInformation(idOfRecipe:Int, completionHandler:(Bool)->Void){
        let parameters=["id":idOfRecipe, "stepBreakdown":true]
        var neverAdd:Bool=false
        Alamofire.request(.GET, "https://spoonacular-recipe-food-nutrition-v1.p.mashape.com/recipes/\(idOfRecipe)/analyzedInstructions?stepBreakdown=true", parameters: parameters as? [String : AnyObject], encoding:ParameterEncoding.URL , headers: head) .responseJSON{ response in
            switch response.result{
            case .Success(let value1):

                let response = value1 as! NSArray
                if(response.count == 0){
                    neverAdd=true
                }
                completionHandler(neverAdd)
            case .Failure(let error):
                print("error:\(error.description)")
             
                    
                }
        }
       
    }
    func getRecipeInformation(id:Int,callback:(Int?, Int?)->Void){
         var parameters = [String:AnyObject]()
        var servings:Int?
        var readyMinutes:Int?
        parameters["id"]=id
        parameters["includeNutrition"]=false
        let iD=parameters["id"] as! Int
        Alamofire.request(.GET, "https://spoonacular-recipe-food-nutrition-v1.p.mashape.com/recipes/\(iD)/information", parameters: parameters, encoding: ParameterEncoding.URL,headers: head) .responseJSON{ response in
            switch response.result{
            case .Success(let value):
                servings=value.objectForKey("servings") as? Int
               readyMinutes=value.objectForKey("readyInMinutes") as? Int
                callback(servings!,readyMinutes!)
            case .Failure(let error):
                print("error:\(error.description)")
            }
        }
        
    }
    override func prepareForSegue(segue: UIStoryboardSegue, sender: AnyObject?) {
        if let identifier=segue.identifier{
            if identifier=="toRecipeTabBarController"{
                let destination=segue.destinationViewController as! RecipeTabBarController
                let firstVC=destination.viewControllers![0] as! DisplayRecipeViewController

                firstVC.image = self.image
                firstVC.imageurl=self.imageURL
                firstVC.titleForRecipe=self.titleOfRecipe!
                firstVC.fat=self.fatResult!
                firstVC.carbs=self.carbsResult!
                firstVC.calories=self.caloriesResult!
                firstVC.protein=self.proteinResult!
                firstVC.servings=self.servings!
                firstVC.readyTime=self.readyTime!
                firstVC.idOfRecipe=self.idOfRecipe!
                
                 let secondVC=destination.viewControllers![1] as! DisplayIngredientsViewController
                secondVC.missedIngredientsCount=self.missedIngredientsCount
                secondVC.idOfRecipe=self.idOfRecipe
                
                let thirdVC=destination.viewControllers![2] as! DisplayStepsProgressViewController
                thirdVC.idOfRecipe=self.idOfRecipe
                
                let fourthVC=destination.viewControllers![3] as! DisplaySimilarRecipesViewController
                fourthVC.idOfRecipe=self.idOfRecipe
            
            }
        }
    }
    @IBAction func unwindToRecipeListViewController(segue: UIStoryboardSegue) {
        for eachItem in recipeList{
            if InformationInputViewController.dislikeIDsList.contains(eachItem.id!){
                if let index=recipeList.indexOf(eachItem){
                    recipeList.removeAtIndex(index)
                }
            }
        }
        self.RecipeTableView.reloadData()
    }
    func tableView(tableView: UITableView, didSelectRowAtIndexPath indexPath: NSIndexPath) {
        let cell = tableView.cellForRowAtIndexPath(indexPath)  as! RecipeListViewCellTableViewCell
        self.image = cell.recipePicImageView?.image
        self.titleOfRecipe=cell.recipeTitleLabel?.text
        self.caloriesResult=cell.caloriesLabel?.text
        self.carbsResult=cell.carbsLabel?.text
        self.fatResult=cell.fatLabel?.text
        self.proteinResult=cell.proteinLabel?.text
        self.servings=cell.servings
        self.readyTime=cell.readyMinutes
        self.missedIngredientsString=cell.missedIngredients
        self.missedIngredientsCount=cell.missedIngredientsCount
        self.idOfRecipe=cell.idOfRecipe
        self.imageURL=cell.imageURL
        self.performSegueWithIdentifier("toRecipeTabBarController", sender: self)
    }

    
  }

    


extension RecipeListViewController:UITableViewDataSource{
    
    func numberOfSectionsInTableView(tableView: UITableView) -> Int {
       return 1
    }
    func tableView(tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return recipeList.count
    }
    
    func tableView(tableView: UITableView, cellForRowAtIndexPath indexPath: NSIndexPath) -> UITableViewCell {
        let cell=tableView.dequeueReusableCellWithIdentifier("RecipeListCell") as! RecipeListViewCellTableViewCell
        let cellBackgroundColor=UIColor(red:251.0/255,green:251.0/255, blue: 251.0/255, alpha: 1)
        cell.contentView.backgroundColor=cellBackgroundColor
        cell.recipePicImageView.image=nil
        let row=indexPath.row
        let recipeSum=recipeList[row]
        cell.recipeTitleTextView.hidden=true
        cell.recipeTitleLabel.backgroundColor=UIColor(red:251.0/255,green:251.0/255, blue: 251.0/255, alpha: 1)
        cell.recipeTitleLabel.text=recipeSum.title
        cell.recipeTitleLabel.textColor=UIColor(red:90.0/255,green:87.0/255, blue: 83.0/255, alpha: 1)
        cell.carbsLabel.textColor=UIColor(red:90.0/255,green:87.0/255, blue: 83.0/255, alpha: 1)
        cell.caloriesLabel.textColor=UIColor(red:90.0/255,green:87.0/255, blue: 83.0/255, alpha: 1)
        cell.fatLabel.textColor=UIColor(red:90.0/255,green:87.0/255, blue: 83.0/255, alpha: 1)
        cell.proteinLabel.textColor=UIColor(red:90.0/255,green:87.0/255, blue: 83.0/255, alpha: 1)
        cell.caloriesLabel.text="Cal: "+recipeSum.calories+"Cal"
        cell.fatLabel.text="Fat: "+recipeSum.fat
        cell.proteinLabel.text="Ptein: "+recipeSum.protein
        cell.carbsLabel.text="Carbs: "+recipeSum.carbs
        cell.servings=recipeSum.servings
        cell.readyMinutes=recipeSum.readyMinutes
        cell.missedIngredientsCount=recipeSum.missedIngredientsCount!
        cell.imageURL=recipeSum.image
        cell.idOfRecipe=recipeSum.id
        cell.recipePicImageView.sd_setImageWithURL(NSURL(string: recipeSum.image),placeholderImage:nil)

     
        return cell
    }
}

