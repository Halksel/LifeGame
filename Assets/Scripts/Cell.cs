using System.Collections;
using System.Collections.Generic;
using UnityEngine;

public class Cell : MonoBehaviour {
	public GameObject aliveCube;
	public GameObject deadCube;
	private CellMgr cellMgr = CellMgr.Instance;

	[SerializeField]
	private bool isAlive;
	public bool isPastAlive {set; get;}
	public int x,y;

	void Awake () {  
		aliveCube.SetActive (true);  
		deadCube.SetActive (false);  
		isAlive = false;  
	}
	public void Init(int _x,int _y,bool _isAlive){
		x = _x;
		y = _y;
		isAlive = _isAlive;
		isPastAlive = _isAlive;
		StartTurn();
	}
	// Use this for initialization
	void Start () {
				
	}
	
	// Update is called once per frame
	void Update () {
		if(Input.GetMouseButtonDown(0)){
			Ray ray = Camera.main.ScreenPointToRay(Input.mousePosition);  
			RaycastHit hit = new RaycastHit();  

			if (Physics.Raycast(ray, out hit)){  
				Cell cell = hit.collider.gameObject.transform.parent.GetComponent<Cell>();  

				if (cell.isAlive) {  
					cell.Die ();  
					cell.isPastAlive = false;
				} else {  
					cell.Birth ();  
					cell.isPastAlive = true;
				}  
			}  
		}
	}
		
	public virtual bool PastTurn(){
		Cell[,] cells = cellMgr.cells;
		int count = 0;
		for(int dx = -1; dx <=1 ;++dx){
			for(int dy = -1; dy <= 1;++dy){
				if(dx == 0 && dy == 0) continue;
				int nx = x + dx,ny = y + dy;
				if(cellMgr.IsValue(nx,ny) && cells[nx,ny].isPastAlive){
					++count;
				}
			}
		}
		if(isPastAlive){ // 前ターン生存なら
			if(count == 2 || count == 3){
				isAlive = true;	
			}
			else{
				isAlive = false;
			}
		}
		else{
			if(count == 3){
				isAlive = true;
			}
		}
		return false;
	}
	public void StartTurn(){
		isPastAlive = isAlive;
		if(isAlive){
			Birth();			
		}
		else{
			Die();
		}
	}
	public void Birth() {  
		deadCube.SetActive (false);  
		aliveCube.SetActive (true);  
	} 
	public void Die() {  
		deadCube.SetActive (true);  
		aliveCube.SetActive (false);  
	} 
}
